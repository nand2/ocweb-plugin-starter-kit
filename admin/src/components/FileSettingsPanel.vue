<script setup>
import { computed, ref, watch } from 'vue'
import { useQueryClient, useMutation } from '@tanstack/vue-query'

import { useIsLocked } from 'ocweb/src/tanstack-vue.js';
import { useStaticFrontendPluginClient, useStaticFrontend, useStaticFrontendFileContent, invalidateStaticFrontendFileContentQuery } from 'ocweb/src/plugins/staticFrontend/tanstack-vue.js';

import PlusLgIcon from './Icons/PlusLgIcon.vue';
import TrashIcon from './Icons/TrashIcon.vue';
import SaveIcon from './Icons/SaveIcon.vue';
import { defaultConfig } from '../assets/defaultConfig';

const props = defineProps({
  contractAddress: {
    type: String,
    required: true,
  },
  chainId: {
    type: Number,
    required: true,
  },
  websiteVersion: {
    type: Object,
    required: true
  },
  websiteVersionIndex: {
    type: Number,
    required: true,
  },
  websiteClient: {
    type: Object,
    required: true,
  },
  pluginsInfos: {
    type: Array,
    required: true,
  },
  pluginInfos: {
    type: Object,
    required: true,
  },
})

const queryClient = useQueryClient()

// Get the lock status
const { data: isLocked, isLoading: isLockedLoading, isFetching: isLockedFetching, isError: isLockedIsError, error: isLockedError, isSuccess: isLockedLoaded } = useIsLocked(props.contractAddress, props.chainId)

// Get the staticFrontendPlugin
const staticFrontendPlugin = computed(() => {
  return props.pluginsInfos.find(plugin => plugin.infos.name == 'staticFrontend')
})

// Get the staticFrontendPluginClient
const { data: staticFrontendPluginClient, isLoading: staticFrontendPluginClientLoading, isFetching: staticFrontendPluginClientFetching, isError: staticFrontendPluginClientIsError, error: staticFrontendPluginClientError, isSuccess: staticFrontendPluginClientLoaded } = useStaticFrontendPluginClient(props.contractAddress, staticFrontendPlugin.value.plugin)

// Get the staticFrontend
const { data: staticFrontend, isLoading: staticFrontendLoading, isFetching: staticFrontendFetching, isError: staticFrontendIsError, error: staticFrontendError, isSuccess: staticFrontendLoaded } = useStaticFrontend(queryClient, props.contractAddress, props.chainId, staticFrontendPlugin.value.plugin, computed(() => props.websiteVersionIndex))

// Get the existing config file infos
const configFileInfos = computed(() => {
  return staticFrontendLoaded.value ? staticFrontend.value.files.find(file => file.filePath == 'themes/about-me/config.json') : null
})

// Fetch the config file content
const { data: fileContent, isLoading: fileContentLoading, isFetching: fileContentFetching, isError: fileContentIsError, error: fileContentError, isSuccess: fileContentLoaded } = useStaticFrontendFileContent(props.contractAddress, props.chainId, staticFrontendPlugin.value.plugin, computed(() => props.websiteVersionIndex), computed(() => configFileInfos.value))

// Decode and load the config
const decodeConfigFileContent = (fileContent) => {
  const decodedConfig = fileContent ? JSON.parse(new TextDecoder().decode(fileContent)) : {};
  return { ...defaultConfig, ...decodedConfig };
}
const config = ref(fileContent.value ? decodeConfigFileContent(fileContent.value) : defaultConfig)
// When the file content is fetched, set the text
watch(fileContent, (newValue) => {
  if(fileContentLoaded.value) {
    config.value = decodeConfigFileContent(newValue)
  }
});

// Computed: Get the list of markdown files (ending by .md), ordered by folder then alphabetically
const markdownFiles = computed(() => {
  if (staticFrontend.value == null) {
    return []
  }

  return staticFrontend.value.files.filter(file => file.filePath.endsWith('.md')).sort((a, b) => {
    // Extract the folder and file name
    const folderA = a.filePath.split('/').slice(0, -1).join('/')
    const folderB = b.filePath.split('/').slice(0, -1).join('/')
    const fileA = a.filePath.split('/').slice(-1)[0]
    const fileB = b.filePath.split('/').slice(-1)[0]

    // Compare the folders
    if (folderA < folderB) {
      return -1
    } else if (folderA > folderB) {
      return 1
    }

    // Compare the files
    if (fileA < fileB) {
      return -1
    } else if (fileA > fileB) {
      return 1
    }
  })
})

// Get the list of existing CSS files
const existingCssFiles = computed(() => {
  if(staticFrontend.value == null) {
    return [];
  }

  return staticFrontend.value.files.filter(file => file.filePath.endsWith('.css')).sort((a, b) => a.filePath.localeCompare(b.filePath));
})

// Determine if the menu has duplicate paths
const menuHasDuplicatePaths = computed(() => {
  const menuItemPaths = config.value.menu.map(menuItem => menuItem.path)
  return (new Set(menuItemPaths)).size !== menuItemPaths.length
})

// Determine if the menu miss an homepage
const menuMissHomepage = computed(() => {
  return config.value.menu.find(menuItem => menuItem.path == '/') == null
})

const hasFormErrors = computed(() => {
  return config.value.title == '' || config.value.menu.find(menuItem => menuItem.title == '' || menuItem.path == '' || menuItem.markdownFile == null) || config.value.externalLinks.find(link => link.title == '' || link.url == '') || menuHasDuplicatePaths.value || menuMissHomepage.value
})
const showFormErrors = ref(false)

// Prepare the addition of files
const filesAdditionTransactions = ref([])
const skippedFilesAdditions = ref([])
const { isPending: prepareAddFilesIsPending, isError: prepareAddFilesIsError, error: prepareAddFilesError, isSuccess: prepareAddFilesIsSuccess, mutate: prepareAddFilesMutate, reset: prepareAddFilesReset } = useMutation({
  mutationFn: async () => {
    // Reset any previous upload
    addFileTransactionBeingExecutedIndex.value = -1
    addFileTransactionResults.value = []

    // Convert the text to a UInt8Array
    const textData = JSON.stringify(config.value, null, 4);

    // Prepare the files for upload
    const fileInfos = [{
      filePath: 'themes/about-me/config.json',
      size: textData.length,
      contentType: "application/json",
      data: textData,
    }]
    console.log(fileInfos)
  
    // Prepare the transaction to upload the files
    const transactionsData = await staticFrontendPluginClient.value.prepareAddFilesTransactions(props.websiteVersionIndex, fileInfos);
    console.log(transactionsData);

    return transactionsData;
  },
  onSuccess: (data) => {
    filesAdditionTransactions.value = data.transactions
    skippedFilesAdditions.value = data.skippedFiles
    // Execute right away, don't wait for user confirmation
    executePreparedAddFilesTransactions()
  }
})
const prepareAddFilesTransactions = async () => {
  showFormErrors.value = false
  addFilesReset()

  // Menu entries: Path: Ensure they start with a /
  config.value.menu.forEach(menuItem => {
    if(menuItem.path.length > 0 && !menuItem.path.startsWith('/')) {
      menuItem.path = '/' + menuItem.path;
    }
  })

  // Validate the form
  if(hasFormErrors.value) {
    showFormErrors.value = true
    return
  }

  prepareAddFilesMutate()
}

// Execute an upload transaction
const addFileTransactionBeingExecutedIndex = ref(-1)
const addFileTransactionResults = ref([])
const { isPending: addFilesIsPending, isError: addFilesIsError, error: addFilesError, isSuccess: addFilesIsSuccess, mutate: addFilesMutate, reset: addFilesReset } = useMutation({
  mutationFn: async ({index, transaction}) => {
    // Store infos about the state of the transaction
    addFileTransactionResults.value.push({status: 'pending'})
    addFileTransactionBeingExecutedIndex.value = index

    const hash = await staticFrontendPluginClient.value.executeTransaction(transaction);
    console.log(hash);

    // Wait for the transaction to be mined
    return await staticFrontendPluginClient.value.waitForTransactionReceipt(hash);
  },
  scope: {
    // This scope will make the mutations run serially
    id: 'addFiles'
  },
  onSuccess: async (data) => {
    // Mark the transaction as successful
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'success'}

    // Refresh the static frontend
    await queryClient.invalidateQueries({ queryKey: ['StaticFrontendPluginStaticFrontend', props.contractAddress, props.chainId, props.websiteVersionIndex] })

    // Refresh the content of the file
    await invalidateStaticFrontendFileContentQuery(queryClient, props.contractAddress, props.chainId, props.websiteVersionIndex, 'themes/about-me/config.json')

    // If this was the last transaction
    if(addFileTransactionBeingExecutedIndex.value == filesAdditionTransactions.value.length - 1) {

    }
  },
  onError: (error) => {
    // Mark the transaction as failed
    addFileTransactionResults.value[addFileTransactionBeingExecutedIndex.value] = {status: 'error', error}
  }
})
const executePreparedAddFilesTransactions = async () => {
  for(const [index, transaction] of filesAdditionTransactions.value.entries()) {
    addFilesMutate({index, transaction})
  }
}

</script>

<template>
  <div class="admin">

    <div class="form-fields">
      <div>
        <label>Site title</label>
        <input v-model="config.title" placeholder="Your name" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
        <div class="text-danger text-80 error-message" v-if="showFormErrors && config.title == ''">
          Required
        </div>
      </div>
      <div>
        <label>Site subtitle <small>Optional</small></label>
        <input v-model="config.subtitle" placeholder="Short description" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
      </div>
    </div>

    <div class="form-fields">
      <div>
        <label>Email <small>Optional</small></label>
        <input v-model="config.email" placeholder="abcd@example.com" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
      </div>

      <div>
        <label>Location <small>Optional</small></label>
        <input v-model="config.location" placeholder="City, ..." :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
      </div>

      <div>
        <label>Advanced: Custom CSS <small>Optional</small></label>
        <select v-model="config.userCssFile" class="form-select" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending">
          <option :value="null">- Select an existing CSS file -</option>
          <option v-for="cssFile in existingCssFiles" :key="cssFile.filePath" :value="cssFile.filePath">{{ cssFile.filePath }}</option>
        </select>
        <div class="text-muted" style="font-size: 0.7em;">
          Activate the developer mode and upload a CSS file in the "Files" section to use it here.
        </div>
      </div>
    </div>

    <div class="menu">
      <h3 style="margin-bottom: 0.3em; display: flex; gap: 0.4em; align-items:center;">
        Menu
        <button @click.stop.prevent="config.menu.push({title: '', path: '', markdownFile: null})" class="sm" style="font-size: 0.7em; display: flex; gap: 0.3em; align-items: center;" v-if="isLockedLoaded && isLocked == false && websiteVersion.locked == false">
          <PlusLgIcon /> Add
        </button>
      </h3>

      <div class="table-header">
        <div>
          Page
        </div>
        <div>
          Title
        </div>
        <div>
          Path
        </div>
        <div></div>
      </div>

      <div v-for="(menuItem, index) in config.menu" :key="index">
        <div class="table-row">
          <div>
            <select v-model="menuItem.markdownFile" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || markdownFiles.length == 0 || prepareAddFilesIsPending || addFilesIsPending">
                <option :value="null">- Select a page -</option>
                <option v-for="file in markdownFiles" :value="file.filePath">{{ file.filePath }}</option>
            </select>
          </div>
          <div>
            <input v-model="menuItem.title" placeholder="Menu title" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
          </div>
          <div>
            <input v-model="menuItem.path" placeholder="e.g. / (homepage), /publications, ..." :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
          </div>
          <div style="line-height: 0em;" v-if="isLockedLoaded && isLocked == false && websiteVersion.locked == false">
            <a @click.stop.prevent="config.menu.splice(index, 1)" class="white">
              <TrashIcon />
            </a>
          </div>
        </div>

        <div class="text-warning text-80" style="margin-left:0.75rem;" v-if="markdownFiles.length == 0 && index == config.menu.length - 1">
          No pages available. Create pages in the "Pages" section.
        </div>
        
        <div class="text-danger text-80 error-message" v-if="showFormErrors && (menuItem.title == '' || menuItem.path == '' || menuItem.markdownFile == null)">
          The page, title and path are required
        </div>
      </div>
    </div>
    <div v-if="showFormErrors && menuHasDuplicatePaths" class="text-danger text-80 error-message" style="margin-left:0.75rem;">
      The menu has duplicate paths
    </div>
    <div v-if="showFormErrors && config.menu.length > 0 && menuMissHomepage" class="text-danger text-80 error-message" style="margin-left:0.75rem;">
      The menu is missing an homepage
    </div>
    <div v-if="config.menu.length == 0" class="text-muted" style="text-align: center; padding: 1em 0em;">
      No menu entries
    </div>

    <div class="outgoing-links">
      <h3 style="margin-bottom: 0.3em; display: flex; gap: 0.4em; align-items:center;">
        External links
        <button @click.stop.prevent="config.externalLinks.push({title: '', url: ''})" class="sm" style="font-size: 0.7em; display: flex; gap: 0.3em; align-items: center;" v-if="isLockedLoaded && isLocked == false && websiteVersion.locked == false">
          <PlusLgIcon /> Add
        </button>
      </h3>

      <div class="table-header">
        <div>
          Title
        </div>
        <div>
          URL
        </div>
        <div></div>
      </div>

      <div v-for="(link, index) in config.externalLinks" :key="index">
        <div class="table-row">
          <div>
            <input v-model="link.title" placeholder="Link title" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
          </div>
          <div>
            <input v-model="link.url" placeholder="web3://example.eth, https://example.com, ..." :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending" />
          </div>
          <div style="line-height: 0em;" v-if="isLockedLoaded && isLocked == false && websiteVersion.locked == false">
            <a @click.stop.prevent="config.externalLinks.splice(index, 1)" class="white">
              <TrashIcon />
            </a>
          </div>
        </div>

        <div class="text-danger text-80 error-message" v-if="showFormErrors && (link.title == '' || link.url == '')">
          The title and URL are required
        </div>
      </div>
      <div v-if="config.externalLinks.length == 0" class="text-muted" style="text-align: center; padding: 1em 0em;">
        No external links
      </div>
    </div>

    <div v-if="hasFormErrors && showFormErrors" class="text-danger text-90">
      Please fix the errors in the form
    </div>

    <div v-if="prepareAddFilesIsError" class="mutation-error">
      <span>
        Error preparing the transaction to save the config: {{ prepareAddFilesError.shortMessage || prepareAddFilesError.message }} <a @click.stop.prevent="prepareAddFilesReset()">Hide</a>
      </span>
    </div>

    <div v-if="addFilesIsError" class="mutation-error">
      <span>
        Error saving the config: {{ addFilesError.shortMessage || addFilesError.message }} <a @click.stop.prevent="addFilesReset()">Hide</a>
      </span>
    </div>

    <div class="buttons">
      <button @click="prepareAddFilesTransactions" :disabled="isLockedLoaded && isLocked || websiteVersion.locked || prepareAddFilesIsPending || addFilesIsPending">
        <span v-if="prepareAddFilesIsPending || addFilesIsPending">
          <SaveIcon class="anim-pulse" />
          Saving in progress...
        </span>
        <span v-else>
          Save
        </span>
      </button>
    </div>

  </div>
</template>

<style scoped>
.admin {
  /* padding: 1em; */
}

label {
  display: block;
  font-weight: bold;
  font-size: 0.9em;
}

label small {
  font-size: 0.8em;
  font-weight: normal;
  color: var(--color-text-muted);
}

.form-fields {
  margin-bottom: 1em;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 1em;
}

.form-fields input, .form-fields select {
  width: 100%;
  box-sizing: border-box;
}

.form-fields .error-message {
  margin-top: 0.2em;
}

.menu .table-header,
.menu .table-row {
  grid-template-columns: 1fr 1fr 1fr 1em;
  align-items: center;
}

.outgoing-links {
  margin-bottom: 1em;
}

.outgoing-links .table-header,
.outgoing-links .table-row {
  grid-template-columns: 1fr 2fr 1em;
  align-items: center;
}

.table-row input,
.table-row select {
  width: 100%;
  box-sizing: border-box
}

.menu .error-message {
  margin-bottom: 0.5em;
  margin-left: 0.75rem;
  margin-right: 0.75rem;
}

.buttons {
  display: flex;
  gap: 1em;
  justify-content: right;
}


</style>
