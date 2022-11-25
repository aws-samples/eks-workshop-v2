# EKS Workshop

Its common for technical documentation to be authored using Markdown files, and for some types of content these can contain large amounts of scripts and commands to be executed by the learner. Its useful to be able to test this type of technical documentation to reduce the chance of regressions, breaking changes etc.

This framework can consume a set of Markdown documents, parse out the `code` blocks and execute these as a suite of unit tests.

Its features include:
- Intelligently parses `bash` code blocks to extract commands that start with `$`, taking in to account multi-line commands and `heredoc` segments
- Recursively parse all Markdown documents in a directory structure
- Order complex sets of content correctly with Frontmatter metadata (`weight`)
- Additional annotations to control test behavior, such as timeouts, skipping specific scripts etc.
- A hook mechanism to plug in 'before' and 'after' actions for each test
- Ability to run subset of tests with globs (`chapter1/**`)
- Support for JUnit report output format

For example, take the following Markdown:

````
---
title: "My Technical Docs"
weight: 10
---

# My Technical Docs

Lets execute this is a command-line:

```bash
$ ls -la
total 6
drwxr-xr-x   24 user  group    768 Sep 15 14:15 .
drwxr-xr-x  143 user  group   4576 Sep  9 17:20 ..
drwxr-xr-x    1 user  group   8196 Aug 18 08:41 dir1
drwxr-xr-x   16 user  group    512 Sep 15 18:36 dir2
drwxr-xr-x    6 user  group    192 Sep 13 09:56 dir3
drwxr-xr-x    1 user  group     87 Aug 26 08:59 dir4
```
````

Output from testing might look like:

```
✔ Generating test cases
✔ Building Mocha suites

Executing tests...


  My Technical Docs
    ✔ My Technical Docs


  1 passing (13ms)

success
```

This will execute the command `ls -la` in a shell. The framework by default will figure out using the `$` that this is the command to run, and understands to ignore the rest of the script block as output.

If we changed the `code` block in the Markdown to this:

````
```bash
$ ls -la
total 6
drwxr-xr-x   24 user  group    768 Sep 15 14:15 .
drwxr-xr-x  143 user  group   4576 Sep  9 17:20 ..
drwxr-xr-x    1 user  group   8196 Aug 18 08:41 dir1
drwxr-xr-x   16 user  group    512 Sep 15 18:36 dir2
drwxr-xr-x    6 user  group    192 Sep 13 09:56 dir3
drwxr-xr-x    1 user  group     87 Aug 26 08:59 dir4
$ touch tester
```
````

Then the command `ls -la` would be executed followed by `touch tester`. You can also use multi-line commands:

````
```bash
cat syslog | \
 awk ‘{print $6}’
```
````

And `heredoc` format:

````
```bash
$ cat <<EOF > /tmp/yourfilehere
some file contents
EOF
```
````

## Usage

Basic usage:

```bash
cli.js test <path to content>
```

Where the structure of the content directory might look something like this:

```
├── _index.md
├── chapter1
│   ├── _index.md
│   └── introduction.md
├── chapter2
│   ├── _index.md
│   └── introduction.md
└── chapter3
    ├── _index.md
    └── introduction.md
```

You can test a specific subsets of the Markdown using the `--glob` parameter:

```
markdown-sh test --glob {chapter1,chapter3}/* .
```

See [test-content](./test-content) for a concrete example.

Theres a chance `markdown-sh` can run on your existing Markdown content unmodified, but it may need some help.

First, make sure that all the code blocks specify `bash` as a language:

````
```
$ echo "This won't get run"
```

```bash
$ echo "This will get run"
```
````

## How does it work?

The tool recursively walks the content directory looking for Markdown files, which are parsed using the `unified` and `remark` libraries. Metadata about the pages (title, weight) are extracted, along with any `code` block that indicates `bash` as the language.

This data is used to programmatically generate a set of tests using the Mocha testing framework, with each "chapter" being modelled as a separate Mocha test suite. These tests are order using the `weight` metadata from Frontmatter if it exists, otherwise it is in alphabetical order.

When the test suites run the commands from the `code` blocks are executed in a persistent shell session, which allows it to maintain things like environment variables set using `export` for the life of the tests.

## Annotations

The framework includes support for a number of annotations that can be added to the `code` fence blocks in Markdown to customize the behavior for certain shell code snippets.

For example, if there are `bash` segments you do not want to run you can indicate they should be skipped:

````
```bash test=false
$ echo "This won't get run"
```
````

For cases where theres a concerned a script might run for too long or not finish, you can specify a timeout in seconds (default is 60 seconds):

````
```bash timeout=120
$ echo "This test case will fail"
$ sleep 150
```
````

Here is a complete list of the available annotations:

| Annotation  | Description  | Default |
|-------------|--------------|---------|
| test        | This script block should be executed as a test                                                                                                                                        | true    |
| timeout     | Time limit in seconds before the script block will be marked as failed                                                                                                                | 120     |
| hook        | Name of the hook to execute for this script section                                                                                                                                   |         |
| hookTimeout | Time limit in seconds for the hooks to complete before the script block will be marked as failed                                                                                      | 300     |
| expectError | Ignore any errors that occur when the script block is executed                                                                                                                        | false   |
| raw         | By default a script block will be smartly interpreted to extract commands and distinguish this from sample output. Enabling this flag will executed the entire script block, assuming there is no output, and will not look for `$` as a prefix for commands | false   |