<!-- CountriesView.vue -->
<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '../supabase'
import CountryBox from '../components/CountryBox.vue'

const route = useRoute()
const router = useRouter()

const props = defineProps({
  phase: {
    type: String,
    default: 'semi1',
  },
})

const activeTab = ref(props.phase)
const countries = ref([])

const tabs = [
  { key: 'semi1', label: 'Semi Final 1' },
  { key: 'semi2', label: 'Semi Final 2' },
  { key: 'final', label: 'Final' },
]

const filteredCountries = computed(() => {
  return countries.value
    .filter((country) => {
      switch (activeTab.value) {
        case 'semi1':
          return country.semi_final === 1
        case 'semi2':
          return country.semi_final === 2
        case 'final':
          return country.final === true
        default:
          return false
      }
    })
    .sort((a, b) => {
      // Use appropriate running order based on phase
      const orderA = activeTab.value === 'final' ? a.final_running_order : a.semi_running_order
      const orderB = activeTab.value === 'final' ? b.final_running_order : b.semi_running_order
      return (orderA || 999) - (orderB || 999) // Handle null values
    })
})

async function fetchCountries() {
  let query = supabase.from('countries').select('*')

  // Filter based on the active tab
  switch (activeTab.value) {
    case 'semi1':
      query = query.eq('semi_final', 1).order('semi_running_order')
      break
    case 'semi2':
      query = query.eq('semi_final', 2).order('semi_running_order')
      break
    case 'final':
      query = query.eq('final', true).order('final_running_order')
      break
  }

  const { data } = await query
  countries.value = data || []
}

function switchTab(tab) {
  activeTab.value = tab
  router.push(`/countries/${tab}`)
  fetchCountries()
}

onMounted(() => {
  fetchCountries()
})
</script>

<template>
  <main>
    <h1>Eurovision Countires</h1>
    <div class="countries-view">
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          @click="switchTab(tab.key)"
          :class="{ active: activeTab === tab.key }"
          class="tab-button"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="countries-list">
        <CountryBox
          v-for="country in filteredCountries"
          :key="country.id"
          :country="country"
          :phase="activeTab"
        />
      </div>
    </div>
  </main>
</template>

<style scoped>
.countries-view {
  padding: 20px;
}

.tabs {
  display: flex;
  gap: 10px;
  margin-bottom: 20px;
}

.tab-button {
  padding: 10px 20px;
  border: 2px solid #ccc;
  background: transparent;
  cursor: pointer;
  border-radius: 5px;
  transition: all 0.3s;
}

.tab-button.active {
  background: var(--accent-color);
  color: white;
  border-color: var(--accent-color);
}

.tab-button:hover {
  background: #f8f9fa;
}

.tab-button.active:hover {
  background: var(--accent-color);
}

.countries-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
</style>
