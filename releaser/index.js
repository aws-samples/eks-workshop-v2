import { Octokit } from "@octokit/rest";

let repository = process.env.GITHUB_REPOSITORY
let sha = process.env.GITHUB_SHA
let milestoneNumber = process.env.MILESTONE_NUMBER

let auth = process.env.GITHUB_TOKEN

let repositoryParts = repository.split('/');
let owner = repositoryParts[0];
let repo = repositoryParts[1];

let tagName = `release-${Math.floor(Date.now() / 1000)}`

const octokit = new Octokit({
  auth
});

const categories = [{
  title: "## 🚀 New labs",
  label: 'new'
}, {
  title: "## ✨ Updated labs",
  label: 'update'
}, {
  title: "## 🐛 Fixes",
  label: 'fix'
}, {
  title: "## 🧪 Features",
  label: 'feat'
}]

let entries = {};

let milestone = await octokit.rest.issues.getMilestone({
  owner,
  repo,
  milestone_number: milestoneNumber,
});

for await (const response of octokit.paginate.iterator(
  octokit.rest.pulls.list,
  {
    owner,
    repo,
    state: 'closed'
  },
)) {
  response.data.forEach((e) => {
    if(e.milestone) {
      if(e.milestone.number == milestoneNumber) {
        categories.forEach((c) => {
          let targetPrefix = `${c.label}:`;

          if(e.title.indexOf(targetPrefix) == 0) {
            if(!entries[c.title]) {
              entries[c.title] = [];
            }

            entries[c.title].push({
              number: e.number,
              title: e.title.substring(targetPrefix.length + 1),
              url: e.html_url,
              author: {
                login: e.user.login,
                url: e.user.html_url,
              }
            });
          }
        })
      }
    }
  })
}

let output = '';

categories.forEach((c) => {
  let categoryOutput = `${c.title}

`;
  if(entries[c.title]) {
    let categoryEntries = entries[c.title];

    if(categoryEntries.length > 0) {
      categoryEntries.forEach((e) => {
        categoryOutput += `- ${e.title} by [@${e.author.login}](${e.author.url}) ([#${e.number}](${e.url}))\n`
      });

      output += `${categoryOutput} \n`;
    }
  }
});

await octokit.rest.git.createRef({
  owner,
  repo,
  ref: `refs/tags/${tagName}`,
  sha,
});

await octokit.rest.repos.createRelease({
  owner,
  repo,
  tag_name: tagName,
  name: milestone.data.title,
  body: output
});