#!/usr/bin/env node

const YAML = require("yaml")
const fs = require("fs")
const glob = require("glob")
const { exit } = require("process")

// read manifest file passed as argument
const manifestFileName = process.argv[2]
const version = process.argv[3]
const file = fs.readFileSync(manifestFileName, "utf8")
const documents = YAML.parseAllDocuments(file)

const kindMap = {
  Role: "role",
  RoleBinding: "rolebinding",
  ClusterRoleBinding: "clusterrolebinding",
  Deployment: "deployment",
  CustomResourceDefinition: "crd",
  Service: "service",
  ClusterRole: "clusterrole",
  ServiceAccount: "serviceaccount",
}

// setup directory for new version
const packagePath = "./flux"
const newVersionDir = `${packagePath}/${version}/`

if (!fs.existsSync(newVersionDir)) {
  fs.mkdirSync(newVersionDir)
}
const manifestsDir = `${newVersionDir}/manifests`
if (!fs.existsSync(manifestsDir)) {
  fs.mkdirSync(manifestsDir)
}
const metadataDir = `${newVersionDir}/metadata`
if (!fs.existsSync(metadataDir)) {
  fs.mkdirSync(metadataDir)
}

// update annotations
const annotations = YAML.parse(
  fs.readFileSync("./templates/annotations.yaml", "utf-8")
)
fs.writeFileSync(`${metadataDir}/annotations.yaml`, YAML.stringify(annotations))
const csv = YAML.parse(
  fs.readFileSync("./templates/clusterserviceversion.yaml", "utf-8")
)
const deployments = []
const crds = []
documents
  .filter((d) => d.contents)
  .map((d) => YAML.parse(String(d)))
  .filter((o) => o.kind !== "NetworkPolicy" && o.kind !== "Namespace") // not supported by operator-sdk
  .map((o) => {
    delete o.metadata.namespace
    switch (o.kind) {
      case "Role":
      case "RoleBinding":
      case "ClusterRoleBinding":
      case "ClusterRole":
      case "Service":
      case "ServiceAccount":
        const filename = `${o.metadata.name}.${kindMap[o.kind]}.yaml`
        fs.writeFileSync(`${manifestsDir}/${filename}`, YAML.stringify(o))
        break
      case "Deployment":
        let deployment = {
          name: o.metadata.name,
          spec: o.spec,
        }
        deployments.push(deployment)
        break
      case "CustomResourceDefinition":
        crds.push(o)
        const crdFileName = `${o.spec.names.singular}.${kindMap[o.kind]}.yaml`
        fs.writeFileSync(`${manifestsDir}/${crdFileName}`, YAML.stringify(o))
        break
      default:
        console.warn(
          "UNSUPPORTED KIND - you must explicitly ignore it or handle it",
          o.kind,
          o.metadata.name
        )
        process.exit(1)
        break
    }
    // d.contents.items.console.log(String(d)) //.contents.items)
  })

// Update ClusterServiceVersion
csv.spec.install.spec.deployments = deployments
csv.metadata.name = `flux.v${version}`
csv.metadata.annotations.containerImage = "ghcr.io/fluxcd/source-controller:v0.15.0"
csv.spec.version = version
csv.spec.minKubeVersion = "1.16.0"
csv.spec.maturity = "stable"
csv.spec.customresourcedefinitions.owned = crds.map((crd) => ({
  name: crd.metadata.name,
  displayName: crd.spec.names.kind,
  kind: crd.spec.names.kind,
  version: crd.spec.versions[0].name,
  description: crd.spec.names.kind,
}))
// TODO: try to remove the replaces requirements
// figure out which version is its predecessor
// const versions = glob
//   .sync(`${packagePath}/*`, { ignore: `${packagePath}/*.yaml` })
//   .map((f) => f.replace(`${packagePath}/`, "")) // only version name
//   .sort((a, b) => parseFloat(a) - parseFloat(b))
// const newVersionIndex = versions.indexOf(version)
// if (newVersionIndex > 0) {
//   csv.spec.replaces = `flux.v${versions[newVersionIndex - 1]}`
// }
const csvFileName = `flux.v${version}.clusterserviceversion.yaml`
fs.writeFileSync(`${manifestsDir}/${csvFileName}`, YAML.stringify(csv))
