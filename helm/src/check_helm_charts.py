import yaml
import requests
import semantic_version
import json
import os
import argparse

def load_chart_requirements(path):
  stream = open(path, "r")

  charts = yaml.safe_load(stream)

  stream.close()

  return charts

def save_terraform_variables(path, vars):
  print('Writing output to {}'.format(path))
  with open(path, 'w') as outfile:
    outfile.write('')
    json.dump(vars, outfile, indent=2, sort_keys=True)

parser = argparse.ArgumentParser()
parser.add_argument("-c", "--config", help="path to charts.yaml", default="charts.yaml")
parser.add_argument("-o", "--output-file", help="path to write JSON output", default = None)
args = parser.parse_args()

charts = load_chart_requirements(args.config)
vars = {
  '//': "This file is auto-generated, do not modify manually",
  'variable': {
    'helm_chart_versions': {
      'default': {}
    }
  }
}

for chart in charts['charts']:
  url = '{}/index.yaml'.format(chart['repository'])
  resp = requests.get(url=url)
  data = yaml.safe_load(resp.content)

  if chart['chart'] not in data['entries']:
    raise Exception('Chart {} does not exist in repository {} - check chart name'.format(chart['chart'], chart['repository']))

  entry = data['entries'][chart['chart']]

  selected_version = ''

  for version in entry:
    if 'constraint' in chart:
      if semantic_version.Version(version['version']) in semantic_version.NpmSpec(chart['constraint']):
        selected_version = version['version']
        break
    else:
      selected_version = version['version']
      break

  if selected_version == '':
    print('Valid version not found')
  else:
    print("Selected version {}:{}".format(chart['name'], version['version']))

    vars['variable']['helm_chart_versions']['default'][chart['name']] = selected_version

if args.output_file is None:
  print('No output file given, skipping writing')
else:
  save_terraform_variables(args.output_file, vars)
