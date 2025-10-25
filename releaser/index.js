import { Octokit } from "@octokit/rest";
import fs from "fs/promises";

const CATEGORIES = [
  {
    title: "## 🚀 New labs",
    label: "new",
  },
  {
    title: "## ✨ Updated labs",
    label: "update",
  },
  {
    title: "## 🐛 Fixes",
    label: "fix",
  },
  {
    title: "## 🧪 Features",
    label: "feat",
  },
];

const CONTENT_LABEL_PREFIX = "content/";

function parseRepositoryString(repository) {
  let repositoryParts = repository.split("/");

  if (repositoryParts.length !== 2) {
    throw new Error(`Repository ${repository} is not valid`);
  }

  return { owner: repositoryParts[0], repo: repositoryParts[1] };
}

function generateMarkdown(entries) {
  let output = "";

  CATEGORIES.forEach((c) => {
    let categoryOutput = `${c.title}

`;
    if (entries[c.title]) {
      let categoryEntries = entries[c.title];

      if (categoryEntries.length > 0) {
        categoryEntries.forEach((e) => {
          categoryOutput += `- ${e.title} by [@${e.author.login}](${e.author.url}) ([#${e.number}](${e.url}))\n`;
        });

        output += `${categoryOutput} \n`;
      }
    }
  });

  return output;
}

async function main() {
  let repository = process.env.GITHUB_REPOSITORY;
  let milestoneNumber = process.env.MILESTONE_NUMBER;

  let auth = process.env.GITHUB_TOKEN;

  let { owner, repo } = parseRepositoryString(repository);

  const octokit = new Octokit({
    auth,
  });

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
      state: "closed",
    },
  )) {
    response.data.forEach((e) => {
      if (e.milestone) {
        if (e.milestone.number == milestoneNumber) {
          const contentLabels = e.labels.filter(
            (e) => e.name.indexOf(CONTENT_LABEL_PREFIX) == 0,
          );
          let contentArea = "";

          if (contentLabels.length > 0) {
            let contentAreaLabel = contentLabels[0].name.substring(
              CONTENT_LABEL_PREFIX.length,
            );
            contentArea = `[${
              contentAreaLabel.charAt(0).toUpperCase() +
              contentAreaLabel.slice(1)
            }] `;
          }

          CATEGORIES.forEach((c) => {
            let targetPrefix = `${c.label}:`;

            if (e.title.indexOf(targetPrefix) == 0) {
              if (!entries[c.title]) {
                entries[c.title] = [];
              }

              entries[c.title].push({
                number: e.number,
                title: `${contentArea}${e.title.substring(
                  targetPrefix.length + 1,
                )}`,
                url: e.html_url,
                author: {
                  login: e.user.login,
                  url: e.user.html_url,
                },
              });
            }
          });
        }
      }
    });
  }

  let output = generateMarkdown(entries);

  try {
    await fs.writeFile("/tmp/release-notes.md", output, "utf8");
    console.log("Successfully wrote release notes to /tmp/release-notes.md");
  } catch (error) {
    console.error("Error writing release notes file:", error);
    throw error;
  }
}

await main();
