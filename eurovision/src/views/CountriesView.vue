<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import CountryBox from '@/components/CountryBox.vue'
import PersonalTop5Modal from '@/components/PersonalTop5.vue'

const user = ref(null)
const router = useRouter()
const showPersonalTop5 = ref(false)
const groupId = ref(null)

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

// reactive data, so automatically updates
const filteredCountries = computed(() => {
  // filter countries based on phase
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

  // get the logged in user
  const { data: authData } = await supabase.auth.getUser()
  if (!authData?.user) return
  user.value = authData.user

  // Get profile
  const { data: profile } = await supabase
    .from('users')
    .select('group_id, name')
    .eq('id', user.value.id)
    .single()

  if (profile) groupId.value = profile.group_id

  // fetch the countries
  query = supabase.from('countries').select('*')

  const { data } = await query
  countries.value = data || []
}

function switchTab(tab) {
  activeTab.value = tab
  router.push(`/countries/${tab}`)
}

// when opening this page, fetch the countries
onMounted(() => {
  fetchCountries()
})
</script>

<template>
  <main class="main">
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

    <!-- Personal Top 5 Button -->
    <div>
      <button @click="showPersonalTop5 = true" class="top-5-button">
        <span>🏆</span>
        <span>Show My Top 5</span>
      </button>
    </div>

    <!-- Personal Top 5 Modal -->
    <PersonalTop5Modal
      :is-open="showPersonalTop5"
      :group-id="groupId"
      :phase="activeTab"
      @close="showPersonalTop5 = false"
    />
  </main>
</template>

<style scoped>
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

.top-5-button {
  margin-top: 20px;
  width: 100%;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.top-5-button:hover {
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}
</style>
