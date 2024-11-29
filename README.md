# OCWebsite Starter Kit Plugin

This plugin is a template to help you make your OCWebsite plugin. Fork it, build it, and experiment with it.

## Building

- Install the [OCWeb](https://github.com/nand2/ocweb) repository, and deploy it locally (cf the `Installation` and `Local deployment` sections)
- Clone this repository at the same level as the `ocweb` folder (the `ocweb-plugin-starter-kit` and `ocweb` folders are in the same folder)
- In the `ocweb` folder, edit `.env`, and set :
  ```
  OCWEB_PLUGINS_BUILD="ocweb-plugin-starter-kit:true:true"
  ```
  This indicates that `ocweb-plugin-starter-kit` needs to be built, and that it will part of the OCWebsite factory plugin library (`true`), and that it will be installed by default when minting a new OCWebsite (`true`)
- Rerun `./scripts/deploy.sh` in the `ocweb` folder : the plugin will be built, and the `example` OCWebsite will be minted with the plugin installed.

## Content

The plugin comes with :

- 2 examples of content serving (via the smart contract itself, or via a proxied OCWebsite in which we upload a static frontend)
- 2 examples of user config storing (in the smart contract, or in a JSON file uploaded to the staticFrontend plugin)
- 2 admin panels to configure these 2 examples of user config.
- Examples of basic functionalities (basic routing, JS `fetch()` example)

## Documentation

Plugin development documentation is [located here at the OCWeb repo](https://github.com/nand2/ocweb?tab=readme-ov-file#develop-your-own-ocwebsite-plugin)
