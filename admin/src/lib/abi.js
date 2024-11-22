export const abi = [
  {
    inputs: [
      {
        internalType: "contract IDecentralizedApp",
        name: "_frontend",
        type: "address"
      },
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "_staticFrontendPlugin",
        type: "address"
      },
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "_ocWebAdminPlugin",
        type: "address"
      }
    ],
    stateMutability: "nonpayable",
    type: "constructor"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "fromFrontendIndex",
        type: "uint256"
      },
      {
        internalType: "uint256",
        name: "toFrontendIndex",
        type: "uint256"
      }
    ],
    name: "copyFrontendSettings",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "frontend",
    outputs: [
      {
        internalType: "contract IDecentralizedApp",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      }
    ],
    name: "getConfig",
    outputs: [
      {
        components: [
          {
            internalType: "string[]",
            name: "rootPath",
            type: "string[]"
          }
        ],
        internalType: "struct ThemeAboutMePlugin.Config",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "infos",
    outputs: [
      {
        components: [
          {
            internalType: "string",
            name: "name",
            type: "string"
          },
          {
            internalType: "string",
            name: "version",
            type: "string"
          },
          {
            internalType: "string",
            name: "title",
            type: "string"
          },
          {
            internalType: "string",
            name: "subTitle",
            type: "string"
          },
          {
            internalType: "string",
            name: "author",
            type: "string"
          },
          {
            internalType: "string",
            name: "homepage",
            type: "string"
          },
          {
            internalType: "contract IVersionableWebsitePlugin[]",
            name: "dependencies",
            type: "address[]"
          },
          {
            components: [
              {
                internalType: "string",
                name: "title",
                type: "string"
              },
              {
                internalType: "string",
                name: "url",
                type: "string"
              },
              {
                internalType: "contract IVersionableWebsitePlugin",
                name: "moduleForGlobalAdminPanel",
                type: "address"
              },
              {
                internalType: "enum IVersionableWebsitePlugin.AdminPanelType",
                name: "panelType",
                type: "uint8"
              }
            ],
            internalType: "struct IVersionableWebsitePlugin.AdminPanel[]",
            name: "adminPanels",
            type: "tuple[]"
          }
        ],
        internalType: "struct IVersionableWebsitePlugin.Infos",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "ocWebAdminPlugin",
    outputs: [
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "string[]",
        name: "resource",
        type: "string[]"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "params",
        type: "tuple[]"
      }
    ],
    name: "processWeb3Request",
    outputs: [
      {
        internalType: "uint256",
        name: "statusCode",
        type: "uint256"
      },
      {
        internalType: "string",
        name: "body",
        type: "string"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "headers",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        internalType: "string[]",
        name: "resource",
        type: "string[]"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "params",
        type: "tuple[]"
      }
    ],
    name: "rewriteWeb3Request",
    outputs: [
      {
        internalType: "bool",
        name: "rewritten",
        type: "bool"
      },
      {
        internalType: "string[]",
        name: "newResource",
        type: "string[]"
      },
      {
        components: [
          {
            internalType: "string",
            name: "key",
            type: "string"
          },
          {
            internalType: "string",
            name: "value",
            type: "string"
          }
        ],
        internalType: "struct KeyValue[]",
        name: "newParams",
        type: "tuple[]"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "contract IVersionableWebsite",
        name: "website",
        type: "address"
      },
      {
        internalType: "uint256",
        name: "websiteVersionIndex",
        type: "uint256"
      },
      {
        components: [
          {
            internalType: "string[]",
            name: "rootPath",
            type: "string[]"
          }
        ],
        internalType: "struct ThemeAboutMePlugin.Config",
        name: "_config",
        type: "tuple"
      }
    ],
    name: "setConfig",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [],
    name: "staticFrontendPlugin",
    outputs: [
      {
        internalType: "contract IVersionableWebsitePlugin",
        name: "",
        type: "address"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4"
      }
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool"
      }
    ],
    stateMutability: "view",
    type: "function"
  }
];