<script setup>
import { defineProps } from 'vue'

const props = defineProps({
  country: {
    type: Object,
    required: true
  }
})

function getFlagUrl(filename) {
  return new URL(`../assets/flags/${filename}`, import.meta.url).href
}
</script>

<template>
  <RouterLink
    :to="{ name: 'VotingPage', params: { countryId: country.id } }"
    class="country-card"
  >
    <img
      :src="getFlagUrl(country.flag)"
      :alt="country.name + ' flag'"
      class="flag"
    />
    <div class="information">
      <div class="country-name">{{ country.name }}</div>
      <div class="artist">{{ country.artist_name }}</div>
      <div class="song-name">{{ country.song_name }}</div>
    </div>
  </RouterLink>
</template>

<style scoped>
.country-card {
  display: flex;
  align-items: center;      /* vertically center flag + text */
  gap: 0.75rem;             /* space between flag & info */
  padding: 0.5rem 1rem;     /* ↓ tighter top/bottom */
  border-radius: 10px;
  color: #fff;
  text-decoration: none;
  box-shadow: 0 0 12px 2px rgba(255, 255, 255, 0.25);
  cursor: pointer;
  user-select: none;
}

.flag {
  height: 40px;             /* pick any height you like */
  width: auto;              /* keeps aspect ratio */
}

.information {
  line-height: 1.2;         /* packs text a bit tighter */
}

.country-name {
  font-weight: 700;
  font-size: 1rem;
  text-transform: uppercase;
}
.artist,
.song-name {
  font-size: 0.85rem;
  opacity: 0.8;
}
</style>

