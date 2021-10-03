import type { BaseModel, Bom, Item } from "./model";

export const defaultBaseModel: BaseModel = {
  uuid: null,
};

export const defaultBom: Bom = {
  ...defaultBaseModel,
  name: "",
};

export const defaultItem: Item = {
  ...defaultBaseModel,
  bomUuid: null,
  link: "",
  name: "",
  price: 0,
  qty: 0,
};
