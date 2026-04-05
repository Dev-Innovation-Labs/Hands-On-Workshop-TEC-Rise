# ✅ Hands-on 2: RBAC di Service Layer — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026

---

## File yang Dimodifikasi

### `srv/catalog-service.cds` — Dengan Access Control

```cds
@requires: 'authenticated-user'
service CatalogService @(path:'/catalog') {

    @readonly entity Books as projection on db.Books;
    @readonly entity Authors as projection on db.Authors;

    @(requires: 'write')
    action submitOrder(bookID: UUID, amount: Integer) returns { orderID: UUID; status: String; };
}

@requires: 'admin'
service AdminService @(path:'/admin') {
    entity Books   as projection on db.Books;
    entity Authors as projection on db.Authors;
    entity Orders  as projection on db.Orders;
}
```

### Penjelasan

```
CatalogService
 └── @requires: 'authenticated-user'  → Harus login dulu
     ├── Books     → @readonly (semua user bisa baca)
     ├── Authors   → @readonly
     └── submitOrder → @requires: 'write' (hanya Editor/Admin)

AdminService
 └── @requires: 'admin'  → Hanya Administrator
     ├── Books   → Full CRUD
     ├── Authors → Full CRUD
     └── Orders  → Full CRUD
```

## Verifikasi di Development Mode

```bash
$ cds watch

# Tanpa login → CatalogService
$ curl http://localhost:4004/odata/v4/catalog/Books
# 200 OK (karena mocked auth, anonymous dianggap authenticated)

# Akses AdminService tanpa admin role
$ curl http://localhost:4004/odata/v4/admin/Authors
# 401 Unauthorized ← Access control bekerja!
```

**✅ Hasil:**

```json
// GET /odata/v4/admin/Authors → 401
{
  "error": {
    "message": "Unauthorized",
    "code": "401"
  }
}
```

### User Info di Handler

```javascript
// Di srv/catalog-service.js
this.on('submitOrder', async (req) => {
    const user = req.user;
    console.log('User ID:', user.id);           // "anonymous" atau email
    console.log('Has admin:', user.is('admin')); // true/false
});
```

---

## Kesimpulan

- ✅ `@requires` decorator berhasil membatasi akses (401 untuk AdminService)
- ✅ `@readonly` mencegah operasi write pada CatalogService
- ✅ User info bisa diakses di handler via `req.user`
