import { getContract, toHex, walletActions, publicActions } from 'viem'

import { abi as themeAboutMePluginABI } from './abi'


class StarterKitPluginClient {
  #viemClient = null
  #websiteContractAddress = null
  #pluginContractAddress = null
  #viemPluginContract = null

  constructor(viemClient, websiteContractAddress, pluginContractAddress) {
    this.#viemClient = viemClient.extend(publicActions).extend(walletActions)
    this.#websiteContractAddress = websiteContractAddress
    this.#pluginContractAddress = pluginContractAddress

    this.#viemPluginContract = getContract({
      address: this.#pluginContractAddress,
      abi: themeAboutMePluginABI,
      client: this.#viemClient,
    })
  }

  async getConfig(frontendIndex) {
    return await this.#viemPluginContract.read.getConfig([this.#websiteContractAddress, frontendIndex])
  }

  async prepareSetConfigTransaction(frontendIndex, config) {
    return {
      functionName: 'setConfig',
      args: [this.#websiteContractAddress, frontendIndex, config],
    }
  }


  /**
   * Execute a transaction prepared by one of the prepare* methods
   */
  async executeTransaction(transaction) {
    const { request } = await this.#viemClient.simulateContract({
      address: this.#pluginContractAddress,
      abi: themeAboutMePluginABI,
      functionName: transaction.functionName,
      args: transaction.args,
    })

    const hash = await this.#viemClient.writeContract(request)

    return hash
  }

  async waitForTransactionReceipt(hash) {
    return await this.#viemClient.waitForTransactionReceipt({
      hash
    })
  }

}

export { StarterKitPluginClient };
