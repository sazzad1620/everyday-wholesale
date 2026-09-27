import type {Firestore} from "firebase-admin/firestore";

import type {Doc, PageData, Route} from "./render";

const MOST_POPULAR_ID = "most_popular";

const asDoc = (snap: FirebaseFirestore.DocumentSnapshot): Doc => ({id: snap.id, ...(snap.data() ?? {})});

/** Loads exactly the data [route] needs to render (see render.ts). */
export async function loadPageData(db: Firestore, route: Route): Promise<PageData> {
  const empty: PageData = {route, categories: [], banners: [], popular: [], products: [], product: null};

  switch (route.kind) {
  case "home": {
    const [categories, banners, popular] = await Promise.all([
      db.collection("categories").get(),
      db.collection("banners").orderBy("order").get(),
      db.collection("products").where("isMostPopular", "==", true).get(),
    ]);
    return {
      ...empty,
      categories: categories.docs.map(asDoc).filter((c) => c.id !== MOST_POPULAR_ID),
      banners: banners.docs.map(asDoc),
      popular: popular.docs.map(asDoc),
    };
  }
  case "category": {
    if (route.categoryId === MOST_POPULAR_ID) {
      const popular = (await db.collection("products").where("isMostPopular", "==", true).get()).docs.map(asDoc);
      return {...empty, popular, products: popular};
    }
    let query: FirebaseFirestore.Query = db.collection("products").where("categoryId", "==", route.categoryId);
    if (route.subcategoryId) query = query.where("subcategoryId", "==", route.subcategoryId);
    const [category, products] = await Promise.all([
      db.collection("categories").doc(route.categoryId).get(),
      query.limit(60).get(),
    ]);
    return {
      ...empty,
      categories: category.exists ? [asDoc(category)] : [],
      products: products.docs.map(asDoc),
    };
  }
  case "product": {
    const product = await db.collection("products").doc(route.productId).get();
    if (!product.exists) return empty;
    const data = asDoc(product);
    const categoryId = typeof data.categoryId === "string" ? data.categoryId : "";
    const category = categoryId ? await db.collection("categories").doc(categoryId).get() : null;
    return {...empty, product: data, categories: category?.exists ? [asDoc(category)] : []};
  }
  default:
    return empty;
  }
}

/** Everything the sitemap lists — only the fields it needs. */
export async function loadSitemapData(db: Firestore): Promise<{categories: Doc[]; products: Doc[]; hasPopular: boolean}> {
  const [categories, products] = await Promise.all([
    db.collection("categories").select().get(),
    db.collection("products").select("categoryId", "isMostPopular").get(),
  ]);
  const productDocs = products.docs.map(asDoc);
  return {
    categories: categories.docs.map(asDoc).filter((c) => c.id !== MOST_POPULAR_ID),
    products: productDocs,
    hasPopular: productDocs.some((p) => p.isMostPopular === true),
  };
}
