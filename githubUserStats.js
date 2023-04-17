// githubUserStats.js

const userName = args[0]
async function fetchGitHubUserStats() {
  const reposUrl = `https://api.github.com/users/${userName}/repos`
  const gistsUrl = `https://api.github.com/users/${userName}/gists`
  const reposAPIRequest = Functions.makeHttpRequest({ url: reposUrl })
  const gistsAPIRequest = Functions.makeHttpRequest({ url: gistsUrl })

  const [reposAPIResponse, gistsAPIResponse] = await Promise.all([reposAPIRequest, gistsAPIRequest])
  const combinedCount = reposAPIResponse.data.length + gistsAPIResponse.data.length
  console.log("Combined repositories and gists count:", combinedCount)
  return combinedCount
}

return Functions.encodeUint256(await fetchGitHubUserStats())
