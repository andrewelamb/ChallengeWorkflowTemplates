#!/usr/bin/env cwl-runner
#
# Since the Synapse Docker registry has the same password as Synapse
# Extract the Synapse credentials and format into Docker config
#
cwlVersion: v1.0
class: CommandLineTool
baseCommand: python

inputs:
  - id: synapse_config
    type: File

arguments:
  - valueFrom: get_docker_config.py
  - valueFrom: $(inputs.synapse_config.path)
    prefix: -c
  - valueFrom: results.json
    prefix: -r

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: get_docker_config.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import base64
          parser = argparse.ArgumentParser()
          parser.add_argument("-r", "--results", required=True, help="validation results")
          parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
          args = parser.parse_args()

          #Must read in credentials (username and password)
          config = synapseclient.Synapse().getConfigFile(configPath=args.synapse_config)
          authen = dict(config.items("authentication"))
          if authen.get("username") is None and authen.get("password") is None:
            raise Exception('Config file must have username and password')
          docker_auth = base64.encodestring("%s:%s" % (authen['username'],authen['password']))

          result = {'docker_auth':docker_auth,'docker_registry':'https://docker.synapse.org'}
          with open(args.results, 'w') as o:
            o.write(json.dumps(result))

outputs:

  - id: results
    type: File
    outputBinding:
      glob: results.json   

  - id: docker_registry
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_registry'])

  - id: docker_authentication
    type: string
    outputBinding:
      glob: results.json
      loadContents: true
      outputEval: $(JSON.parse(self[0].contents)['docker_auth'])
