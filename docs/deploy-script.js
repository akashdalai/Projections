const exec = require('child_process').exec;
const site = process.env.URL;
console.log('site is:');
console.log('site is:');
console.log('site is:');
console.log('site is:');
console.log(site);
const subdomain = site.split('/')[site.split('/').length - 1];

let buildCommand;
switch (subdomain) {
  case 'docs':
    buildCommand = 'npm install -g gitdocs@latest && gitdocs build';
    break;
  case 'storybook':
    buildCommand = 'cd .. && npm run build-storybook';
    break;
  default:
    throw `Domain ${subdomain} is invalid`;
}

async function execute(command) {
  return await exec(command, function(error, stdout, stderr) {
    if (error) {
      throw error;
    }
    console.log(`site: ${site}`);
    console.log(`domain: ${subdomain}`);
    console.log(stdout);
  });
}

execute(buildCommand);
