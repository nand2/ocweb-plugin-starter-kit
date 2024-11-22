// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import "ocweb/contracts/src/interfaces/IVersionableWebsite.sol";
import "ocweb/contracts/src/interfaces/IDecentralizedApp.sol";
import "./library/LibStrings.sol";

contract StarterKitPlugin is ERC165, IVersionableWebsitePlugin {
    // Link to plugin dependencies
    IVersionableWebsitePlugin public staticFrontendPlugin;
    IVersionableWebsitePlugin public ocWebAdminPlugin;

    // If your plugin has a admin configuration page / module, you can link it here
    IDecentralizedApp public adminFrontend;
    // If your plugin has frontend files hosted on another OCWebsite (or other web3:// website), you can link it here
    IDecentralizedApp public frontend;
    
    

    struct Config {
        string[] rootPath;
    }
    mapping(IVersionableWebsite => mapping(uint => Config)) private configs;

    constructor(IDecentralizedApp _frontend, IVersionableWebsitePlugin _staticFrontendPlugin, IVersionableWebsitePlugin _ocWebAdminPlugin) {
        frontend = _frontend;
        staticFrontendPlugin = _staticFrontendPlugin;
        ocWebAdminPlugin = _ocWebAdminPlugin;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return
            interfaceId == type(IVersionableWebsitePlugin).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * IVersionableWebsitePlugin interface
     * Declare the plugin infos
     */
    function infos() external view returns (Infos memory) {
        // The dependencies of your plugin
        IVersionableWebsitePlugin[] memory dependencies = new IVersionableWebsitePlugin[](2);
        dependencies[0] = staticFrontendPlugin;
        dependencies[1] = ocWebAdminPlugin;

        AdminPanel[] memory adminPanels = new AdminPanel[](1);
        // This admin panel is a JS UMD module for the primary "Admin interface" plugin
        adminPanels[0] = AdminPanel({
            title: "Starter Kit Plugin",
            // The URL to the JS UMD module. It can be a relative or absolute web3:// URL
            url: "/plugins/starter-kit/admin.umd.js",
            // This indicate that this is a JS UMD module for the admin interface provided by the ocWebAdminPlugin plugin
            moduleForGlobalAdminPanel: ocWebAdminPlugin,
            // Hint to where to display the admin panel
            // - Primary : Displayed as a tab in the main admin interface
            // - Secondary : Displayed when using the "configure" button in the plugin admin page
            panelType: AdminPanelType.Secondary
        });

        return
            Infos({
                name: "starterKit",
                version: "0.1.0",
                title: "Starter Kit",
                subTitle: "A starter kit to make OCWebsite plugins",
                author: "yourName",
                homepage: "web3://yourAddress.eth/",
                dependencies: dependencies,
                adminPanels: adminPanels
            });
    }

    /**
     * IVersionableWebsitePlugin interface
     * The OCWebsite will call this function to process a request.
     * If the function return statusCode = 0, the OCWebsite will continue to the next plugin.
     * @param website The OCWebsite that is calling the plugin
     * @param websiteVersionIndex The index of the website version that is calling the plugin
     * @param resource The resource path of the request (e.g. /a/b?g=1&h=2 will be ["a", "b"])
     * @param params The query parameters of the request (e.g. /a/b?g=1&h=2 will be [{key: "g", value: "1"}, {key: "h", value: "2"}])
     * @return statusCode The HTTP status code of the response (200, 404, 302, ...)
     * @return body The body of the response. Can be binary data (see docs as to why it is "string" type)
     * @return headers The HTTP headers of the response. Each header is a key-value pair.
     */
    function processWeb3Request(
        IVersionableWebsite website,
        uint websiteVersionIndex,
        string[] memory resource,
        KeyValue[] memory params
    )
        external view override returns (uint statusCode, string memory body, KeyValue[] memory headers)
    {
        //
        // Serve the main frontend. 2 options : directly from plugin, or proxying from another OCWebsite
        //

        // We take into account the configured rootPath by the user.
        // The path /[config.rootPath]/* will be proxied to /* in the frontend OCWebsite
        Config memory config = configs[website][websiteVersionIndex];        
        if(resource.length >= config.rootPath.length) {
            bool prefixMatch = true;
            for(uint i = 0; i < config.rootPath.length; i++) {
                if(Strings.equal(resource[i], config.rootPath[i]) == false) {
                    prefixMatch = false;
                    break;
                }
            }

            // 
            if(prefixMatch) {
                // Prepare the path without the rootPath
                string[] memory unprefixedResource = new string[](resource.length - config.rootPath.length);
                for(uint i = 0; i < resource.length - config.rootPath.length; i++) {
                    unprefixedResource[i] = resource[i + config.rootPath.length];
                }

                //
                // Frontend option 1 :
                // Serve the frontend directly from the plugin
                //

                // Frontpage
                if(resource.length == 0) {
                    body = "<html>"
                            "<head>"
                                "<title>Starter Kit Plugin</title>"
                            "</head>"
                            "<body>"
                                "<h1>Welcome to the Starter Kit Plugin</h1>"
                                "<p>This is a starter kit to make OCWebsite plugins</p>"
                                "<p>Base Fee fetched: <span id='baseFee'>Loading...</span></p>"
                                "<script>"
                                    "function fetchBaseFee() {"
                                        "fetch('/api/basefee')"
                                            ".then(response => response.json())"
                                            ".then(data => {"
                                                "document.getElementById('baseFee').innerText = data.baseFee;"
                                            "})"
                                            ".catch(error => {"
                                                "console.error('Error fetching base fee:', error);"
                                            "});"
                                    "}"
                                    "setInterval(fetchBaseFee, 12000);"
                                    "fetchBaseFee();"
                                "</script>"
                            "</body>"
                        "</html>";
                    statusCode = 200;
                    headers = new KeyValue[](1);
                    headers[0].key = "Content-type";
                    headers[0].value = "text/html";
                }
                // /index/[uint]
                else if(resource.length >= 1 && resource.length <= 2 && ToString.compare(resource[0], "index")) {
                    uint page = 1;
                    if(resource.length == 2) {
                        page = ToString.stringToUint(resource[1]);
                    }
                    if(page == 0) {
                        statusCode = 404;
                    }
                    else {
                        body = "<html>"
                                "<head>"
                                    "<title>Starter Kit Plugin</title>"
                                "</head>"
                                "<body>"
                                    "<h1>Index page " + ToString.uintToString(page) + "</h1>"
                                    "<p>This is the index page " + ToString.uintToString(page) + "</p>"
                                "</body>"
                            "</html>";
                        statusCode = 200;
                        headers = new KeyValue[](1);
                        headers[0].key = "Content-type";
                        headers[0].value = "text/html";
                    }
                }
                // /api/basefee
                else if(resource.length == 2 && Strings.equal(resource[0], "api") && Strings.equal(resource[1], "basefee")) {
                    uint baseFee = block.basefee;
                    body = "{ \"baseFee\": " + ToString.uintToString(baseFee) + " }";
                    statusCode = 200;
                    headers = new KeyValue[](1);
                    headers[0].key = "Content-type";
                    headers[0].value = "application/json";
                }

                //
                // Frontend option 2 : 
                // Serve the frontend by proxing static files stored in an outside OCWebsite
                //

                // Do the proxy call to the frontend OCWebsite
                (statusCode, body, headers) = frontend.request(unprefixedResource, params);

                // ERC-7774 cache-control header alteration
                headers = alterProxiedRequestResponseCacheHeaders(frontend, unprefixedResource, params, headers);

                return (statusCode, body, headers);
            }
        }

        //
        // Serve the admin UMD module, whose files are stored in an outside OCWebsite
        // The path /plugins/starter-kit/* will be proxied to /admin/* in the adminFrontend OCWebsite
        //

        if (resource.length >= 2 && Strings.equal(resource[0], "plugins") && Strings.equal(resource[1], "starter-kit")) {
            string[] memory proxiedResource = new string[](resource.length - 1);
            proxiedResource[0] = "admin";
            for (uint i = 2; i < resource.length; i++) {
                proxiedResource[i - 1] = resource[i];
            }

            // Do the proxy call to the adminFrontend OCWebsite
            (statusCode, body, headers) = adminFrontend.request(proxiedResource, params);

            // ERC-7774 cache-control header alteration
            headers = alterProxiedRequestResponseCacheHeaders(adminFrontend, proxiedResource, params, headers);

            return (statusCode, body, headers);
        }


    }

    /**
     * IVersionableWebsitePlugin interface
     * When an OCWebsite creates a new version, it can copy the settings of a previous version.
     * You will need to : 
     * - Check if the caller is the owner of the website
     */
    function copyFrontendSettings(IVersionableWebsite website, uint fromFrontendIndex, uint toFrontendIndex) public {
        // Only the OCWebsite can call this function
        require(address(website) == msg.sender);

        Config storage config = configs[website][toFrontendIndex];
        Config storage fromConfig = configs[website][fromFrontendIndex];

        config.rootPath = fromConfig.rootPath;
    }

    /**
     * IVersionableWebsitePlugin interface
     * Do some internal rewrite of the request. For most cases, you don't want to use this. If you want to do 
     * some internal redirect for your own plugin, do it in the processWeb3Request function.
     */
    function rewriteWeb3Request(IVersionableWebsite website, uint websiteVersionIndex, string[] memory resource, KeyValue[] memory params) external view returns (bool rewritten, string[] memory newResource, KeyValue[] memory newParams) {
        return (false, new string[](0), new KeyValue[](0));
    }

    /**
     * Non-interface function : expose a config
     */
    function getConfig(IVersionableWebsite website, uint websiteVersionIndex) external view returns (Config memory) {
        return configs[website][websiteVersionIndex];
    }

    /**
     * Non-interface function : set a config
     * You will need to :
     * - Check if the caller is the owner of the website, or the website itself
     * - Since the OCWebsite owner can call this, check if the website is not globally locked
     * - Since the OCWebsite owner can call this, check if the website version is not locked
     */
    function setConfig(IVersionableWebsite website, uint websiteVersionIndex, Config memory _config) external {
        // Ownership check
        require(address(website) == msg.sender || website.owner() == msg.sender, "Not the owner");

        // Global OCWebsite lock check
        require(website.isLocked() == false, "Website is locked");

        // Website version lock check
        require(websiteVersionIndex < website.getWebsiteVersionCount(), "Website version out of bounds");
        IVersionableWebsite.WebsiteVersion memory websiteVersion = website.getWebsiteVersion(websiteVersionIndex);
        require(websiteVersion.locked == false, "Website version is locked");

        Config storage config = configs[website][websiteVersionIndex];

        config.rootPath = _config.rootPath;
    }

    /**
     * ERC-7774
     * Alter the Cache-control: evm-events response headers of a proxied request to include the address of the proxied website.
     * This function is not perfect and will not work correctly if:
     * - The Cache-control header contains multiple directives (e.g. "Cache-control: evm-events, max-age=3600")
     * - The proxiedResource and proxiedParams contains characters that should be URI-percent-encoded
     */
    function alterProxiedRequestResponseCacheHeaders(IDecentralizedApp proxiedWebsite, string[] memory proxiedResource, KeyValue[] memory proxiedParams, KeyValue[] memory responseHeaders) internal view returns (KeyValue[] memory) {
        // ERC-7774
        // If there is a "Cache-control: evm-events" response header, we will replace it with 
        // "Cache-control: evm-events=<addressOfProxiedWebsite><proxiedResource><proxiedParams>"
        // That way, we indicate that the contract emitting the ERC-7774 cache clearing events is 
        // the proxied website
        for(uint i = 0; i < responseHeaders.length; i++) {
            if(LibStrings.compare(responseHeaders[i].key, "Cache-control") && LibStrings.compare(responseHeaders[i].value, "evm-events")) {
                string memory path = "/";
                for(uint j = 0; j < newResource.length; j++) {
                    path = string.concat(path, newResource[j]);
                    if(j < newResource.length - 1) {
                        path = string.concat(path, "/");
                    }
                }
                if(proxiedParams.length > 0) {
                    path = string.concat(path, "?");
                    for(uint j = 0; j < proxiedParams.length; j++) {
                        path = string.concat(path, proxiedParams[j].key, "=", proxiedParams[j].value);
                        if(j < proxiedParams.length - 1) {
                            path = string.concat(path, "&");
                        }
                    }
                }
                headers[i].value = string.concat("evm-events=", "\"", LibStrings.toHexString(address(frontend)), path, "\"");
            }
        }

        return responseHeaders;
    }
}