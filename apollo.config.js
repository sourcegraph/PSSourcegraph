// For autocompletion in .graphql files in VS Code.
module.exports = {
  client: {
    service: {
      name: 'sourcegraph',
      url: 'https://sourcegraph.com/.api/graphql',
    },
    includes: ['./PSSourcegraph/queries/**/*.graphql'],
  },
}
