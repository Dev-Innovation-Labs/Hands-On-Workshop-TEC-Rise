# ✅ Hands-on 2: Custom Event Handlers — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026  
> **CDS Version:** @sap/cds v9.8.4

---

## File yang Dibuat

### `srv/catalog-service.js`

```javascript
const cds = require('@sap/cds');

module.exports = class CatalogService extends cds.ApplicationService {
    async init() {
        const { Books, Reviews, OrderItems } = this.entities;

        // BEFORE: Validasi Books
        this.before('CREATE', 'Books', (req) => {
            const { title, price } = req.data;
            if (!title || title.trim() === '') req.reject(400, 'Book title is required');
            if (price !== undefined && price < 0) req.reject(400, 'Price cannot be negative');
        });

        // BEFORE: Validasi Reviews
        this.before('CREATE', 'Reviews', (req) => {
            if (req.data.rating < 1 || req.data.rating > 5)
                req.reject(400, 'Rating must be between 1 and 5');
        });

        // AFTER: Computed field stockStatus
        this.after('READ', 'Books', (books) => {
            for (const book of Array.isArray(books) ? books : [books]) {
                if (book.stock !== undefined) {
                    book.stockStatus = book.stock > 10 ? 'High'
                        : book.stock > 0 ? 'Low' : 'Out of Stock';
                }
            }
        });

        // ON: Logging
        this.on('READ', 'Books', async (req, next) => {
            console.log(`[CatalogService] READ Books — User: ${req.user?.id}`);
            return next();
        });

        // FUNCTION: countBooksForAuthor
        this.on('countBooksForAuthor', async (req) => {
            const result = await SELECT.from(Books).where({ author_ID: req.data.authorID });
            return result.length;
        });

        // ACTION: submitOrder
        this.on('submitOrder', async (req) => {
            const { bookID, amount } = req.data;
            const book = await SELECT.one(Books).where({ ID: bookID });
            if (!book) req.reject(404, `Book ${bookID} not found`);
            if (book.stock < amount) req.reject(409, `Insufficient stock. Available: ${book.stock}`);

            await UPDATE(Books).set({ stock: book.stock - amount }).where({ ID: bookID });
            const orderID = cds.utils.uuid();
            await INSERT.into(OrderItems).entries({
                ID: cds.utils.uuid(), parent_ID: orderID,
                book_ID: bookID, amount, netAmount: book.price * amount,
            });
            return { orderID, status: 'CONFIRMED', message: `Order for ${amount}x "${book.title}" confirmed.` };
        });

        return super.init();
    }
};
```

## Lifecycle Hooks — Verifikasi

```
Request masuk
     │
     ▼
  BEFORE handlers   ← Validasi title wajib, price >= 0, rating 1-5
     │
     ▼
  ON handlers       ← Logging user ID, custom action/function logic
     │
     ▼
  AFTER handlers    ← Tambah computed field stockStatus
     │
     ▼
  Response keluar
```

### Test BEFORE Handler (Validasi)

```bash
# Test: Create book tanpa title → harus ditolak
$ curl -X POST http://localhost:4004/odata/v4/catalog/Books \
  -H "Content-Type: application/json" \
  -d '{"price": 10}'

# Response:
{
  "error": {
    "message": "Book title is required",
    "code": "400"
  }
}
```

### Test AFTER Handler (Computed Field)

```bash
$ curl http://localhost:4004/odata/v4/catalog/Books?\$top=2

# Response — perhatikan field stockStatus ditambahkan:
# stock: 12 → stockStatus: "High" (lebih dari 10)
# stock: 11 → stockStatus: "High"
```

### Test ON Handler (Logging)

```
# Di terminal server muncul:
[CatalogService] READ Books — User: anonymous
```

---

## Kesimpulan

- ✅ BEFORE handler berhasil menolak request yang tidak valid (400)
- ✅ AFTER handler berhasil menambahkan computed field `stockStatus`
- ✅ ON handler berhasil melakukan logging
- ✅ ACTION `submitOrder` dan FUNCTION `countBooksForAuthor` berfungsi
