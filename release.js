#!/usr/bin/env node

const YAML = require("yaml")
const fs = require("fs")

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
}

// setup directory for new version
const newVersionDir = `./flux/${version}/`
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
csv.spec.install.spec.deployments = []

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
      case "Service":
        const filename = `${o.metadata.name}.${kindMap[o.kind]}.yaml`
        fs.writeFileSync(`${manifestsDir}/${filename}`, YAML.stringify(o))
        break
      case "Deployment":
        let deployment = {
          name: o.metadata.name,
          spec: o.spec,
        }
        csv.spec.install.spec.deployments.push(deployment)
        break
      case "CustomResourceDefinition":
        const crdFileName = `${o.spec.names.singular}.${kindMap[o.kind]}.yaml`
        fs.writeFileSync(`${manifestsDir}/${crdFileName}`, YAML.stringify(o))
        break
    }
    // d.contents.items.console.log(String(d)) //.contents.items)
  })

const csvFileName = `flux.${version}.clusterserviceversion.yaml`
fs.writeFileSync(`${manifestsDir}/${csvFileName}`, YAML.stringify(csv))
