# Summer2

BOM List manager for summing up your project budget. 2nd version of [Summer](https://github.com/vmasdani/summer).  

Why a new repository? Because the stack is totally different.  

- Summer uses native CSS, [Elm](https://elm-lang.org/), and native IndexedDB (which is really hard to maintain for this simple use-case)
- Summer2 uses [TailwindCSS](https://tailwindcss.com/), [AlpineJS](https://alpinejs.dev/), and [idb-keyval](https://github.com/jakearchibald/idb-keyval)

![summer2](summer2.png)

I plan to add:
- JSON import <-> export and interoperability with Summer v1
- Different currencies
- Online storage/synchronization
- BoM duplication for similar BoM list
- Link for online shopping reference

### Running
1. Install `npm i`
2. Run `npm run serve` for development