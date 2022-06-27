import yaml
import requests
import semantic_version
import json
import os

def load_chart_requirements():
  stream = open("charts.yaml", "r")

  charts = yaml.safe_load(stream)

  stream.close()

  return charts

def load_terraform_variables(path):
  f = open(path)

  data = json.load(f)
 
  f.close()

  return data

def save_terraform_variables(path, vars):
  print('Writing output to {}'.format(path))
  with open(path, 'w') as outfile:
    outfile.write('')
    json.dump(vars, outfile, indent=2, sort_keys=True)

charts = load_chart_requirements()
vars = {
  '//': "This file is auto-generated, do not modify manually",
  'variable': {
    'helm_chart_versions': {
      'default': {}
    }
  }
}

target_file = os.getenv('TARGET_FILE', '../terraform/modules/cluster/helm_versions.tf.json')

for chart in charts['charts']:
  url = '{}/index.yaml'.format(chart['repository'])
  resp = requests.get(url=url)
  data = yaml.safe_load(resp.content)

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

save_terraform_variables(target_file, vars)