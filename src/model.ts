export interface BaseModel {
  uuid?: string | null;
}

export interface Bom extends BaseModel {
  name?: string | null;
}

export interface Item extends BaseModel {
  uuid?: string | null;
  bomUuid?: string | null;
  link?: string | null;
  name?: string | null;
  price?: number | null;
  qty?: number | null;
}
