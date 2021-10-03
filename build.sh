rm -rf src/tailwind.css &&\
NODE_ENV=production postcss tailwind.css -o src/tailwind.css &&\
npm run build &&\
rm -rf dist &&\
mkdir dist &&\
cp -r public/* dist &&\
echo 'Build available in dist.'