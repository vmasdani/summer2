<script lang="ts">
  import { onMount } from "svelte";
  import Plus from "svelte-material-icons/Plus.svelte";
  import Delete from "svelte-material-icons/Delete.svelte";
  import Copy from "svelte-material-icons/ContentCopy.svelte";
  import eye from "svelte-material-icons/Eye.svelte";

  import "./tailwind.css";
  import { v4 as uuidv4 } from "uuid";

  import * as idbKeyVal from "idb-keyval";

  import type { Bom, Item } from "./model";
  import { defaultBom, defaultItem } from "./defaultModel";
  import Overlay from "./Overlay.svelte";
  import { appOverlay } from "./Stores";
  import LoadingComponent from "./LoadingComponent.svelte";
  import { action_destroyer } from "svelte/internal";
  import Eye from "svelte-material-icons/Eye.svelte";

  export let name: string;
  let bomVisible = false;

  let items: Item[] = [];
  let boms: Bom[] = [];
  let overlay = false;
  let searchBom = "";
  let selectedBomUuid: string | null = null;
  let showBoms = true;

  appOverlay.subscribe((o) => {
    overlay = o;
  });

  const initTable = async <T extends unknown>(
    name: string,
    item: T,
    callback: () => Promise<void>
  ) => {
    const items = (await idbKeyVal.get(name)) as T[] | null | undefined;

    if (!items) {
      await callback();
      return [] as T[];
    } else {
      return items;
    }
  };

  const addBom = async () => {
    overlay = true;

    boms = [
      ...boms,
      {
        ...defaultBom,
        uuid: uuidv4(),
      },
    ];

    await idbKeyVal.set("boms", boms);

    overlay = false;
  };

  const addBomItem = async () => {
    overlay = true;

    items = [
      ...items,
      {
        ...defaultItem,
        bomUuid: selectedBomUuid,
        uuid: uuidv4(),
      },
    ];

    await idbKeyVal.set("items", items);

    overlay = false;
  };

  onMount(async () => {
    overlay = true;

    const [bomsIdb, itemsIdb] = await Promise.all(
      [
        {
          table: "boms",
          default: { ...defaultBom } as Bom,
          callback: async () => {
            await idbKeyVal.set("boms", []);
          },
        },
        {
          table: "items",
          default: { ...defaultItem } as Item,
          callback: async () => {
            await idbKeyVal.set("items", []);
          },
        },
      ].map(async (table) =>
        initTable(table.table, table.default, table.callback)
      )
    );

    console.log("boms", bomsIdb, "items", itemsIdb);

    overlay = false;

    boms = bomsIdb;
    items = itemsIdb;
  });

  const handleDeleteBom = async (uuid: string) => {
    const confirmation = window.confirm("Really delete?");

    if (confirmation) {
      overlay = true;

      boms = boms.filter((bomX) => bomX.uuid !== uuid);
      await idbKeyVal.set("boms", boms);

      overlay = false;
    }
  };

  const handleCopyBom = async (uuid: string) => {
    const bomName = window.prompt(
      "Enter bom name:",
      `${boms.find((bom) => bom.uuid === uuid)?.name ?? ""} copy`
    );

    const foundBom = boms.find((bom) => bom.uuid === uuid);

    if (foundBom) {
      const newBom = {
        ...foundBom,
        uuid: uuidv4(),
        name: bomName,
      };

      boms = [...boms, newBom];

      items = [
        ...items,
        ...items
          .filter((item) => item.bomUuid === uuid)
          .map((item) => ({ ...item, uuid: uuidv4(), bomUuid: newBom.uuid })),
      ];

      overlay = true;
      await idbKeyVal.set("boms", boms);
      await idbKeyVal.set("items", items);
      overlay = false;
    }
  };

  const changeBomName = async (e: Event, uuid: string) => {
    const foundBom = boms.find((bomX) => bomX.uuid === uuid);

    console.log(foundBom?.name, (e.target as HTMLInputElement).value);

    if (foundBom?.name !== (e.target as HTMLInputElement).value) {
      overlay = true;
      foundBom.name = (e.target as HTMLInputElement).value;
      boms = boms;
      await idbKeyVal.set("boms", boms);
      overlay = false;
    }
  };

  const changeItemPrice = async (e: Event, uuid: string) => {
    const foundItem = items.find((item) => item.uuid === uuid);

    if (foundItem) {
      overlay = true;

      foundItem.price = isNaN(
        parseFloat((e.target as HTMLInputElement).value ?? "")
      )
        ? foundItem.price
        : parseFloat((e.target as HTMLInputElement).value ?? "");

      items = items;
      await idbKeyVal.set("items", items);
      overlay = false;
    }
  };

  const changeItemQty = async (e: Event, uuid: string) => {
    const foundItem = items.find((item) => item.uuid === uuid);

    if (foundItem) {
      overlay = true;

      foundItem.qty = isNaN(
        parseFloat((e.target as HTMLInputElement).value ?? "")
      )
        ? foundItem.qty
        : parseFloat((e.target as HTMLInputElement).value ?? "");

      items = items;
      await idbKeyVal.set("items", items);
      overlay = false;
    }
  };

  const setSearchBom = (e: Event) => {
    searchBom = (e.target as HTMLInputElement).value;
  };

  const changeItemName = async (e: Event, uuid: string) => {
    const foundItem = items.find((item) => item.uuid === uuid);

    if (foundItem?.name !== (e.target as HTMLInputElement)?.value) {
      overlay = true;
      foundItem.name = (e.target as HTMLInputElement).value;
      items = items;
      await idbKeyVal.set("items", items);
      overlay = false;
    }
  };

  $: filteredBoms = boms.filter((bom) =>
    bom?.name?.toLowerCase().includes(searchBom?.toLowerCase() ?? "")
  );

  $: filteredItems = items.filter((item) => item.bomUuid === selectedBomUuid);
</script>

<main>
  <div class="container mx-auto p-2">
    <div class="flex justify-center ">
      <div>
        <h2
          class="font-bold text-gray-600 bg-green-300 border-4 border-green-600 p-3 rounded-lg"
        >
          Summer
        </h2>
      </div>
    </div>
    <div class="flex justify-center container mx-auto">
      <div class="italic">Your simple BoM List Manager</div>
    </div>
    <div class="flex items-center">
      <div>Pick your BoM</div>

      <button
        class="mx-2 text-red-500 border-2 border-red-300 p-1 flex  justify-center items-center"
        on:click={() => {
          addBom();
        }}
        >Add <Plus />
      </button>
    </div>
    <hr class="my-3" />

    <div class="flex items-center">
      <input
        class="px-2 py-1 border-2 rounded-md border-gray-300"
        placeholder="Search BoM..."
        on:input={setSearchBom}
      />
      <div>
        <button
          class="flex items-center bg-green-500 hover:bg-green-700 font-bold text-white p-2 rounded-lg mx-2"
          on:click={() => {
            showBoms = !showBoms;
          }}
          >Toggle BoM <div class="mx-1"><Eye /></div>
        </button>
      </div>
    </div>

    {#if showBoms}
      {#each filteredBoms as bom, i}
        <div class=" p-1 my-2 border-2 border-gray-300">
          <div class="flex items-center">
            <div class="mx-1 p-2">
              <button
                on:click={() => {
                  selectedBomUuid = bom.uuid;
                }}
                class={`${
                  selectedBomUuid === bom.uuid
                    ? `bg-green-500 hover:bg-green-700`
                    : `bg-blue-500 hover:bg-blue-700`
                } px-2 py-1 text-white font-bold`}>Select</button
              >
            </div>
            <div class="flex-grow">
              <input
                placeholder="Input BoM name..."
                on:blur={(e) => changeBomName(e, bom.uuid)}
                value={bom.name}
                class="border-2 w-full px-2 py-1"
              />
            </div>

            <div class="mx-1">
              <button
                class="p-2 bg-blue-200"
                on:click={() => handleCopyBom(bom?.uuid)}><Copy /></button
              >
            </div>

            <div class="mx-1">
              <button
                class="p-2 bg-red-200"
                on:click={() => handleDeleteBom(bom?.uuid)}><Delete /></button
              >
            </div>
          </div>
          <!-- <div>
          {bom.name}
        </div> -->
          <div>
            {(() => {
              const filteredItems = items.filter(
                (item) => item.bomUuid === bom?.uuid
              );

              return `Price: ${Intl.NumberFormat("eu-EU").format(
                filteredItems?.reduce(
                  (acc, bom) => acc + (bom.qty ?? 0) * (bom.price ?? 0),
                  0
                )
              )}, Items: ${filteredItems?.length}`;
            })()}
          </div>

          <!-- <div>
          <hr class="border border-blue-300" />
        </div> -->
        </div>
      {/each}
    {/if}

    {#if overlay}
      <Overlay compo={LoadingComponent} />
    {/if}

    {#if selectedBomUuid}
      <div>
        <hr class="my-3" />
        <div class="flex items-center">
          <h4 class="text-lg font-bold">
            Items for {boms.find((bom) => bom.uuid === selectedBomUuid)?.name}
          </h4>
          <div class="mx-2">
            <button
              on:click={addBomItem}
              class="p-1 border-2 border-red-300 text-red-600 flex items-center"
              ><Plus /> Add</button
            >
          </div>
        </div>
        <div class="my-2">
          <table class="table-auto w-full">
            <thead>
              <tr>
                {#each ["#", "Name", "Qty", "Price", "Total"] as head}
                  <th class="border-2 border-gray-400">{head}</th>
                {/each}
              </tr>
            </thead>
            {#each filteredItems as item, i}
              <tbody>
                <tr>
                  <td class="border-2 border-gray-400 p-1">
                    {i + 1}
                  </td>
                  <td class="content-center border-2 border-gray-400 p-1">
                    <input
                      class="w-full border-2 border-gray-500 px-2 py-1"
                      placeholder="Item..."
                      value={item?.name}
                      on:blur={(e) => changeItemName(e, item.uuid)}
                    />
                  </td>
                  <td class="content-center border-2 border-gray-400 p-1">
                    <input
                      class="w-full border-2 border-gray-500 px-2 py-1"
                      placeholder="Qty..."
                      value={item?.qty}
                      style="width:75px"
                      on:blur={(e) => changeItemQty(e, item.uuid)}
                    />
                  </td>
                  <td class="content-center border-2 border-gray-400 p-1">
                    <input
                      class="w-full border-2 border-gray-500 px-2 py-1"
                      placeholder="Price..."
                      value={item?.price}
                      on:blur={(e) => changeItemPrice(e, item.uuid)}
                    />
                  </td>
                  <td class="content-center border-2 border-gray-400 p-1">
                    <!-- {item?.price}
                    {item?.qty} -->
                    {Intl.NumberFormat("eu-EU").format(
                      (item?.price ?? 0) * (item?.qty ?? 0)
                    )}
                  </td>
                </tr>
              </tbody>
            {/each}
            <tr>
              <td class="border-2 border-gray-400 p-2 font-bold" colspan="4"
                >Total</td
              >
              <td class="border-2 border-gray-400 p-1 font-bold"
                >{Intl.NumberFormat("eu-EU").format(
                  filteredItems.reduce(
                    (acc, item) => acc + (item?.price ?? 0) * (item?.qty ?? 0),
                    0
                  )
                )}</td
              >
            </tr>
          </table>
        </div>
      </div>
    {/if}
  </div>
</main>
