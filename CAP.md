# SAP CAP vs Laravel — Komparasi Komprehensif

> **Penulis:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development
> **SAP Certified — BTP, ABAP, Fiori, BDC** | Tel: 0881 0805 34116

---

## Daftar Isi

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Identitas Framework](#2-identitas-framework)
3. [Filosofi & Arsitektur](#3-filosofi--arsitektur)
4. [Project Structure](#4-project-structure)
5. [Data Modeling](#5-data-modeling)
6. [Service / API Layer](#6-service--api-layer)
7. [Business Logic](#7-business-logic)
8. [Authentication & Authorization](#8-authentication--authorization)
9. [Database & ORM](#9-database--orm)
10. [Frontend / UI](#10-frontend--ui)
11. [Testing](#11-testing)
12. [Deployment](#12-deployment)
13. [CLI Commands](#13-cli-commands)
14. [Ekosistem & Integrasi](#14-ekosistem--integrasi)
15. [Performance & Scalability](#15-performance--scalability)
16. [Learning Curve](#16-learning-curve)
17. [Kapan Pakai Yang Mana?](#17-kapan-pakai-yang-mana)
18. [Side-by-Side Code Comparison (Bookshop)](#18-side-by-side-code-comparison-bookshop)
19. [Kesimpulan](#19-kesimpulan)

---

## 1. Ringkasan Eksekutif

| Aspek | **SAP CAP** | **Laravel** |
|-------|------------|-------------|
| **Bahasa** | Node.js / Java + CDS | PHP |
| **Target** | Enterprise SAP, cloud-native | Web umum, SaaS, startup |
| **API Style** | OData v4 (auto-generated) | REST (manual routing) |
| **Database** | HANA Cloud, SQLite, PostgreSQL | MySQL, PostgreSQL, SQLite, SQL Server |
| **Auth** | XSUAA / IAS (SAP BTP) | Session, Sanctum, Passport, Socialite |
| **UI** | SAP Fiori Elements (auto-generated) | Blade, Livewire, Inertia.js |
| **Deploy** | SAP BTP (CF / Kyma) | Any server, AWS, GCP, Forge, Vapor |
| **Lisensi** | SAP Commercial + Open Source (CDS) | MIT (100% Open Source) |
| **Maturity** | 2018+ (v9.x saat ini) | 2011+ (v11.x saat ini) |

**Analogi Sederhana:**
- **CAP** = Meal kit premium (Bahan + resep + alat khusus → hasil enterprise-grade)
- **Laravel** = Meal kit populer (Bahan + resep fleksibel → hasil web app apapun)

Keduanya **opinionated framework** — kamu ikuti konvensinya, framework generate sisanya.

---

## 2. Identitas Framework

### SAP CAP (Cloud Application Programming Model)

```
Publisher  : SAP SE
Language   : CDS (Core Data Services) + Node.js atau Java
First      : 2018
Current    : v9.8.x (April 2026)
License    : Apache 2.0 (CDS runtime) + SAP Commercial (BTP services)
Repository : https://github.com/SAP/cloud-cap-samples
Package    : @sap/cds, @sap/cds-dk
```

### Laravel

```
Publisher  : Taylor Otwell / Laravel LLC
Language   : PHP 8.x
First      : 2011
Current    : v11.x (April 2026)
License    : MIT (100% open source)
Repository : https://github.com/laravel/laravel
Package    : laravel/framework (Composer)
```

---

## 3. Filosofi & Arsitektur

### CAP: Domain-Driven, Protocol-Agnostic

```
┌─────────────────────────────────────┐
│           CDS Model Layer           │  ← Single source of truth
│  (schema.cds + service.cds)         │
├──────────┬──────────┬───────────────┤
│  OData   │  REST    │  GraphQL*     │  ← Auto-generated protocols
├──────────┴──────────┴───────────────┤
│        Service Runtime (Node/Java)  │  ← Event-driven handlers
├─────────────────────────────────────┤
│     Database (HANA / SQLite / PG)   │  ← Auto DDL + deploy
└─────────────────────────────────────┘

* GraphQL via plugin
```

**Prinsip CAP:**
- **CDS First** — Model data sekali, generate semua (DB, API, UI annotations)
- **Convention over Configuration** — Nama file = nama service
- **Grow As You Go** — Mulai SQLite lokal → deploy HANA Cloud production
- **Protocol Agnostic** — Satu CDS model, expose di OData/REST/GraphQL
- **Event-Driven** — `before/on/after` hooks untuk business logic

### Laravel: MVC, Elegant PHP

```
┌─────────────────────────────────────┐
│           Routes (web.php/api.php)  │  ← URL → Controller mapping
├─────────────────────────────────────┤
│           Controllers               │  ← Request handling
├──────────┬──────────────────────────┤
│  Models  │  Views (Blade/API JSON)  │  ← Eloquent ORM + Templates
├──────────┴──────────────────────────┤
│        Service Providers / Middleware│  ← DI Container + Pipeline
├─────────────────────────────────────┤
│     Database (MySQL / PG / SQLite)  │  ← Migration + Seeder
└─────────────────────────────────────┘
```

**Prinsip Laravel:**
- **MVC Pattern** — Model, View, Controller terpisah jelas
- **Expressive Syntax** — Code yang bisa dibaca seperti kalimat bahasa Inggris
- **Convention over Configuration** — Nama model = nama tabel (singular → plural)
- **Dependency Injection** — Service Container otomatis resolve dependencies
- **Middleware Pipeline** — Request → Middleware chain → Response

---

## 4. Project Structure

### CAP Bookshop Project

```
bookshop/
├── package.json          ← Dependencies + CDS config
├── mta.yaml              ← Multi-Target Application descriptor (deploy)
├── db/
│   ├── schema.cds        ← Data model (satu file = semua entity)
│   └── data/
│       ├── Books.csv      ← Initial data (auto-import)
│       └── Authors.csv
├── srv/
│   ├── catalog-service.cds  ← Service definition (projections)
│   └── catalog-service.js   ← Business logic (event handlers)
├── app/
│   └── books/
│       ├── annotations.cds   ← UI annotations (Fiori Elements)
│       └── webapp/           ← Fiori UI5 app
└── test/
    └── catalog.test.js
```

**Jumlah file untuk REST API + DB + Auth: ~5 file**

### Laravel Bookshop Project

```
bookshop/
├── composer.json
├── .env                        ← Environment config
├── artisan                     ← CLI entry point
├── routes/
│   ├── web.php                 ← Web routes
│   └── api.php                 ← API routes
├── app/
│   ├── Models/
│   │   ├── Book.php            ← Eloquent model
│   │   ├── Author.php
│   │   ├── Genre.php
│   │   ├── Order.php
│   │   └── Review.php
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── BookController.php
│   │   │   ├── AuthorController.php
│   │   │   └── OrderController.php
│   │   ├── Middleware/
│   │   │   └── AdminMiddleware.php
│   │   └── Requests/
│   │       └── StoreBookRequest.php
│   └── Policies/
│       └── BookPolicy.php
├── database/
│   ├── migrations/
│   │   ├── create_books_table.php
│   │   ├── create_authors_table.php
│   │   ├── create_genres_table.php
│   │   ├── create_orders_table.php
│   │   └── create_reviews_table.php
│   └── seeders/
│       ├── BookSeeder.php
│       └── AuthorSeeder.php
├── resources/
│   └── views/
│       └── books/
│           ├── index.blade.php
│           └── show.blade.php
└── tests/
    └── Feature/
        └── BookTest.php
```

**Jumlah file untuk REST API + DB + Auth: ~20+ file**

### Verdict: Jumlah Boilerplate

| Metric | CAP | Laravel |
|--------|-----|---------|
| Files untuk CRUD API | ~3 (schema.cds + service.cds + service.js) | ~8 (model + migration + controller + route + request) |
| Lines of Code untuk 5-entity app | ~150 | ~500+ |
| Auto-generated | DB schema, OData API, CRUD operations, $filter/$orderby/$expand | Tidak ada (manual semua) |

---

## 5. Data Modeling

### CAP — CDS (Core Data Services)

```cds
// db/schema.cds — REAL dari project bookshop TEC Rise
namespace com.tecrise.bookshop;
using { Currency, managed, cuid } from '@sap/cds/common';

entity Authors : cuid, managed {
    name         : String(100) not null;
    dateOfBirth  : Date;
    placeOfBirth : String(100);
    books        : Association to many Books on books.author = $self;
}

entity Books : cuid, managed {
    title    : String(150) not null;
    descr    : String(1000);
    author   : Association to Authors;
    genre    : Association to Genres;
    stock    : Integer default 0;
    price    : Decimal(10,2);
    currency : Currency;
    reviews  : Composition of many Reviews on reviews.book = $self;
}
```

**Apa yang di-generate otomatis dari CDS di atas:**
- ✅ Tabel database (DDL) — `CREATE TABLE`, foreign keys, indexes
- ✅ UUID primary key (`cuid` aspect)
- ✅ Audit fields `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` (`managed` aspect)
- ✅ OData Entity Type + Navigation Properties
- ✅ Association → Foreign Key + `$expand` support
- ✅ Composition → Deep insert/update/delete

### Laravel — Eloquent + Migration

```php
// database/migrations/create_books_table.php
Schema::create('books', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->string('title', 150);
    $table->text('descr')->nullable();
    $table->foreignUuid('author_id')->constrained()->cascadeOnDelete();
    $table->string('genre_code', 4)->nullable();
    $table->integer('stock')->default(0);
    $table->decimal('price', 10, 2)->nullable();
    $table->string('currency_code', 3)->nullable();
    $table->timestamps(); // created_at, updated_at
});

// app/Models/Book.php
class Book extends Model
{
    use HasUuids;

    protected $fillable = ['title', 'descr', 'stock', 'price', 'currency_code'];

    public function author(): BelongsTo
    {
        return $this->belongsTo(Author::class);
    }

    public function genre(): BelongsTo
    {
        return $this->belongsTo(Genre::class, 'genre_code', 'code');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }
}
```

### Perbandingan Data Modeling

| Fitur | CAP CDS | Laravel Eloquent |
|-------|---------|------------------|
| **Definisi schema** | 1 file `.cds` | 2 file (Migration + Model) |
| **Relasi** | `Association to` / `Composition of` | `belongsTo()` / `hasMany()` |
| **UUID auto** | `cuid` aspect | `HasUuids` trait |
| **Audit trail** | `managed` aspect | `$table->timestamps()` |
| **Deep operations** | Composition = auto deep CRUD | Manual `with()` + event listeners |
| **Reusable types** | `using { Currency } from '@sap/cds/common'` | Custom cast classes |
| **Multi-tenancy** | Built-in (MTX) | Manual / Tenancy package |
| **Type safety** | Strong CDS types | PHP type hints + casts |
| **Localization** | `localized` aspect = auto i18n table | Manual translation tables |

---

## 6. Service / API Layer

### CAP — CDS Service Definition

```cds
// srv/catalog-service.cds — REAL dari project bookshop
using { com.tecrise.bookshop as db } from '../db/schema';

@requires: 'authenticated-user'
service CatalogService @(path: '/catalog') {

    @readonly
    entity Books as projection on db.Books {
        *,
        author.name as authorName
    } excluding { orders };

    @readonly
    entity Authors as projection on db.Authors;

    action submitOrder(bookID: UUID, amount: Integer) returns {
        orderID : UUID;
        status  : String;
    };

    function countBooksForAuthor(authorID: UUID) returns Integer;
}
```

**Dari CDS di atas, otomatis tersedia:**

```
GET    /catalog/Books                              ← List (+ $filter, $orderby, $top, $skip, $search)
GET    /catalog/Books(guid'...')                    ← Read by key
GET    /catalog/Books?$expand=author,reviews        ← Deep read
GET    /catalog/Books?$filter=stock gt 10           ← Filtering
GET    /catalog/Books?$orderby=price desc           ← Sorting
GET    /catalog/Books/$count                        ← Count
GET    /catalog/Authors                             ← Author list
POST   /catalog/submitOrder                         ← Bound action
GET    /catalog/countBooksForAuthor(authorID=...)   ← Function
GET    /catalog/$metadata                           ← OData metadata (XML)
```

**Total lines of CDS: ~15 → Endpoints generated: 20+**

### Laravel — Routes + Controller

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('books', BookController::class)->only(['index', 'show']);
    Route::apiResource('authors', AuthorController::class)->only(['index', 'show']);
    Route::post('orders/submit', [OrderController::class, 'submit']);
    Route::get('books/{book}/author-count', [BookController::class, 'countByAuthor']);
});

// app/Http/Controllers/BookController.php
class BookController extends Controller
{
    public function index(Request $request)
    {
        $query = Book::with('author');

        // Manual: filtering
        if ($request->has('min_stock')) {
            $query->where('stock', '>=', $request->min_stock);
        }

        // Manual: sorting
        if ($request->has('sort')) {
            $direction = $request->get('direction', 'asc');
            $query->orderBy($request->sort, $direction);
        }

        // Manual: searching
        if ($request->has('search')) {
            $query->where('title', 'like', '%' . $request->search . '%');
        }

        return BookResource::collection($query->paginate(20));
    }

    public function show(Book $book)
    {
        return new BookResource($book->load(['author', 'reviews']));
    }
}

// app/Http/Resources/BookResource.php
class BookResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'         => $this->id,
            'title'      => $this->title,
            'descr'      => $this->descr,
            'stock'      => $this->stock,
            'price'      => $this->price,
            'authorName' => $this->whenLoaded('author', fn() => $this->author->name),
        ];
    }
}
```

### Perbandingan API Layer

| Fitur | CAP | Laravel |
|-------|-----|---------|
| **Routing** | Otomatis dari CDS | Manual `Route::` definition |
| **CRUD** | Built-in (0 code) | `apiResource` + Controller methods |
| **Filtering** | `$filter=stock gt 10` (OData standard) | Manual query parameter parsing |
| **Sorting** | `$orderby=price desc` (otomatis) | Manual `orderBy()` |
| **Pagination** | `$top=20&$skip=40` (otomatis) | `->paginate(20)` |
| **Search** | `$search=keyword` (otomatis) | Manual `where LIKE` |
| **Expand/Include** | `$expand=author` (otomatis) | `->load('author')` (manual) |
| **Response format** | OData JSON (standard) | Custom Resource class |
| **API Documentation** | `$metadata` (auto-generated XML) | Swagger/OpenAPI (manual) |
| **Protocol** | OData v4 | REST (custom) |

---

## 7. Business Logic

### CAP — Event Handlers

```javascript
// srv/catalog-service.js — REAL dari project bookshop
const cds = require('@sap/cds');

module.exports = class CatalogService extends cds.ApplicationService {

    async init() {
        const Books = 'com.tecrise.bookshop.Books';

        // BEFORE hook: Validasi sebelum create
        this.before('CREATE', 'Books', (req) => {
            const { title, price } = req.data;
            if (!title?.trim()) req.reject(400, 'Book title is required');
            if (price < 0) req.reject(400, 'Price cannot be negative');
        });

        // AFTER hook: Tambah computed field setelah read
        this.after('READ', 'Books', (results) => {
            for (const book of Array.isArray(results) ? results : [results]) {
                book.stockStatus = book.stock > 10 ? 'High'
                    : book.stock > 0 ? 'Low' : 'Out of Stock';
            }
        });

        // ACTION: Custom business logic
        this.on('submitOrder', async (req) => {
            const { bookID, amount } = req.data;
            const book = await SELECT.one(Books).where({ ID: bookID });
            if (!book) req.reject(404, `Book not found`);
            if (book.stock < amount) req.reject(409, `Insufficient stock`);

            await UPDATE(Books)
                .set({ stock: book.stock - amount })
                .where({ ID: bookID });

            return { orderID: cds.utils.uuid(), status: 'Confirmed' };
        });

        await super.init();
    }
};
```

### Laravel — Controller + Form Request + Observer

```php
// app/Http/Requests/StoreBookRequest.php
class StoreBookRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'title' => 'required|string|max:150',
            'price' => 'nullable|numeric|min:0',
        ];
    }
}

// app/Http/Controllers/BookController.php
class BookController extends Controller
{
    public function store(StoreBookRequest $request)
    {
        $book = Book::create($request->validated());
        return new BookResource($book);
    }
}

// app/Observers/BookObserver.php — Computed field
class BookObserver
{
    public function retrieved(Book $book): void
    {
        $book->stockStatus = match(true) {
            $book->stock > 10 => 'High',
            $book->stock > 0  => 'Low',
            default            => 'Out of Stock',
        };
    }
}

// app/Http/Controllers/OrderController.php
class OrderController extends Controller
{
    public function submit(Request $request)
    {
        $request->validate([
            'bookID' => 'required|uuid|exists:books,id',
            'amount' => 'required|integer|min:1',
        ]);

        $book = Book::findOrFail($request->bookID);

        if ($book->stock < $request->amount) {
            return response()->json([
                'error' => 'Insufficient stock'
            ], 409);
        }

        $book->decrement('stock', $request->amount);

        $order = Order::create([
            'buyer'    => auth()->user()->name,
            'book_id'  => $book->id,
            'quantity' => $request->amount,
        ]);

        return response()->json([
            'orderID' => $order->id,
            'status'  => 'Confirmed',
        ]);
    }
}
```

### Perbandingan Business Logic

| Pattern | CAP | Laravel |
|---------|-----|---------|
| **Validasi** | `this.before('CREATE', ...)` | Form Request / `$request->validate()` |
| **Computed fields** | `this.after('READ', ...)` | Model Observer / Accessor |
| **Custom action** | `this.on('submitOrder', ...)` | Controller method |
| **Error handling** | `req.reject(code, message)` | `abort()` / `response()->json()` |
| **Query builder** | `SELECT.from()`, `UPDATE()` | Eloquent `Book::where()`, `->update()` |
| **Transaction** | `cds.tx()` | `DB::transaction()` |
| **Events** | `srv.emit('orderCreated', ...)` | `event(new OrderCreated(...))` |
| **Hook lifecycle** | `before → on → after` | Observer: `creating → created` |

---

## 8. Authentication & Authorization

### CAP — Annotation-Based

```cds
// srv/catalog-service.cds
@requires: 'authenticated-user'        // ← Seluruh service butuh login
service CatalogService {
    @readonly entity Books as ...;      // ← Hanya GET (auto-enforced)
    @(requires: 'write')
    action submitOrder(...);            // ← Butuh role 'write'
}

@requires: 'admin'                     // ← Butuh role admin
service AdminService {
    entity Books as projection on db.Books;  // ← Full CRUD
}
```

```json
// xs-security.json — XSUAA configuration
{
    "xsappname": "bookshop",
    "scopes": [
        { "name": "$XSAPPNAME.write", "description": "Write access" },
        { "name": "$XSAPPNAME.admin", "description": "Admin access" }
    ],
    "role-templates": [
        { "name": "Writer", "scope-references": ["$XSAPPNAME.write"] },
        { "name": "Admin",  "scope-references": ["$XSAPPNAME.admin"] }
    ]
}
```

**Cara kerja:** CDS runtime auto-check JWT token → extract scopes → match `@requires` → 403 jika tidak punya role.

### Laravel — Middleware + Policy + Gate

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('books', [BookController::class, 'index']);
    Route::post('orders', [OrderController::class, 'submit'])
        ->middleware('can:create-order');
});

Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function () {
    Route::apiResource('books', Admin\BookController::class);
});

// app/Http/Middleware/AdminMiddleware.php
class AdminMiddleware
{
    public function handle(Request $request, Closure $next)
    {
        if (! $request->user()->is_admin) {
            abort(403, 'Admin access required');
        }
        return $next($request);
    }
}

// app/Policies/BookPolicy.php
class BookPolicy
{
    public function createOrder(User $user): bool
    {
        return $user->hasPermission('write');
    }
}
```

### Perbandingan Auth

| Fitur | CAP | Laravel |
|-------|-----|---------|
| **Auth method** | JWT (XSUAA/IAS) | Session, Sanctum, Passport |
| **Role definition** | `xs-security.json` | DB roles / Spatie Permission |
| **Access control** | `@requires` annotation | Middleware + Policy + Gate |
| **Multi-tenant** | Built-in (SaaS MTX) | Manual / Tenancy package |
| **SSO** | SAP IAS, SAML, OIDC | Socialite, Custom OIDC |
| **Effort** | 1 annotation = done | Middleware + Policy + Gate class |
| **Granularity** | Service/Entity/Action level | Route/Controller/Model level |
| **Token handling** | Auto (CAP runtime) | Manual middleware config |

---

## 9. Database & ORM

### CAP — CDS Query Language (CQL)

```javascript
// SELECT
const books = await SELECT.from('Books')
    .where({ stock: { '>=': 10 } })
    .orderBy('title')
    .limit(20, 40);

// Dengan expand (deep read)
const book = await SELECT.one('Books')
    .where({ ID: bookID })
    .columns(b => {
        b.title, b.price,
        b.author(a => { a.name }),
        b.reviews(r => { r.rating, r.text })
    });

// INSERT
await INSERT.into('Books').entries({
    title: 'Clean Code',
    price: 39.99,
    author_ID: authorID
});

// UPDATE
await UPDATE('Books')
    .set({ stock: { '-=': amount } })
    .where({ ID: bookID });

// DELETE
await DELETE.from('Books').where({ ID: bookID });

// UPSERT
await UPSERT.into('Books').entries(booksArray);
```

### Laravel — Eloquent ORM

```php
// SELECT
$books = Book::where('stock', '>=', 10)
    ->orderBy('title')
    ->skip(40)->take(20)
    ->get();

// Dengan eager loading (deep read)
$book = Book::with(['author:id,name', 'reviews:id,book_id,rating,text'])
    ->select('id', 'title', 'price')
    ->find($bookID);

// INSERT
Book::create([
    'title'     => 'Clean Code',
    'price'     => 39.99,
    'author_id' => $authorID,
]);

// UPDATE
Book::where('id', $bookID)
    ->decrement('stock', $amount);

// DELETE
Book::destroy($bookID);

// UPSERT
Book::upsert($booksArray, ['id'], ['title', 'stock', 'price']);
```

### Perbandingan Database

| Fitur | CAP CQL | Laravel Eloquent |
|-------|---------|------------------|
| **Style** | Fluent API (SQL-like) | Fluent API (method chain) |
| **Deep read** | Auto via `$expand` / CQL columns | Manual `with()` / `load()` |
| **Deep insert** | Composition = auto recursive save | Manual `saveMany()` / events |
| **Migration** | Auto from CDS model (`cds deploy`) | Manual migration files |
| **Seeding** | CSV files (auto-import) | Seeder classes + Faker |
| **Caching** | Built-in query caching | Manual `Cache::remember()` |
| **DB switching** | `cds.requires.db.kind` = sqlite/hana/postgres | `.env` DB_CONNECTION |
| **Raw SQL** | `cds.run('SELECT ...')` | `DB::select('SELECT ...')` |
| **Soft delete** | Custom aspect | `SoftDeletes` trait |
| **N+1 prevention** | Auto (OData batch) | `preventLazyLoading()` |

---

## 10. Frontend / UI

### CAP — Fiori Elements (Annotation-Driven)

```cds
// app/books/annotations.cds
annotate CatalogService.Books with @(
    UI: {
        // List page columns
        LineItem: [
            { Value: title,      Label: 'Title' },
            { Value: authorName, Label: 'Author' },
            { Value: stock,      Label: 'Stock',
              Criticality: stockCriticality },           // ← Auto traffic light
            { Value: price,      Label: 'Price' }
        ],
        // Detail page header
        HeaderInfo: {
            TypeName: 'Book', TypeNamePlural: 'Books',
            Title: { Value: title },
            Description: { Value: authorName }
        },
        // Detail page fields
        FieldGroup #Main: {
            Data: [
                { Value: title },
                { Value: descr },
                { Value: price },
                { Value: stock }
            ]
        }
    }
);
```

**Hasil:** Full-featured UI (tabel, sorting, filtering, detail page, responsive) — **0 baris JavaScript/HTML.**

### Laravel — Blade / Livewire / Inertia

```php
// resources/views/books/index.blade.php
@extends('layouts.app')

@section('content')
<div class="container">
    <table class="table">
        <thead>
            <tr>
                <th>Title</th>
                <th>Author</th>
                <th>Stock</th>
                <th>Price</th>
            </tr>
        </thead>
        <tbody>
            @foreach($books as $book)
            <tr>
                <td><a href="{{ route('books.show', $book) }}">{{ $book->title }}</a></td>
                <td>{{ $book->author->name }}</td>
                <td>
                    <span class="badge bg-{{ $book->stock > 10 ? 'success' : ($book->stock > 0 ? 'warning' : 'danger') }}">
                        {{ $book->stock }}
                    </span>
                </td>
                <td>{{ number_format($book->price, 2) }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
    {{ $books->links() }} {{-- Pagination --}}
</div>
@endsection
```

### Perbandingan Frontend

| Fitur | CAP + Fiori Elements | Laravel + Blade |
|-------|---------------------|-----------------|
| **Approach** | Annotation-driven (declarative) | Template-driven (imperative) |
| **Code untuk list page** | ~15 lines CDS annotations | ~40 lines HTML/Blade |
| **Responsive** | Otomatis (Fiori Elements) | Manual (Bootstrap/Tailwind) |
| **Filtering/Sorting** | Built-in (OData + SmartTable) | Manual implementation |
| **i18n** | Built-in (Fiori framework) | `__('key')` translation |
| **Design system** | SAP Fiori Design Guidelines | Kustom (Tailwind/Bootstrap) |
| **Flexibility** | Terbatas pada Fiori patterns | Unlimited creativity |
| **Learning curve** | Perlu paham annotations | Familiar HTML + PHP |
| **Mobile** | Responsive Fiori Elements | Manual responsive design |

---

## 11. Testing

### CAP

```javascript
// test/catalog.test.js
const cds = require('@sap/cds');

describe('Bookshop Tests', () => {
    const { GET, POST, expect } = cds.test('serve', '--in-memory');

    it('should list books', async () => {
        const { data } = await GET('/catalog/Books');
        expect(data.value).to.have.length.greaterThan(0);
    });

    it('should reject unauthenticated', async () => {
        const res = await GET('/catalog/Books', { auth: null });
        expect(res.status).to.equal(401);
    });

    it('should submit order', async () => {
        const { data } = await POST('/catalog/submitOrder', {
            bookID: '...', amount: 2
        }, { auth: { username: 'writer', password: 'writer' } });
        expect(data.status).to.equal('Confirmed');
    });
});
```

### Laravel

```php
// tests/Feature/BookTest.php
class BookTest extends TestCase
{
    use RefreshDatabase;

    public function test_list_books(): void
    {
        Book::factory()->count(5)->create();

        $response = $this->actingAs(User::factory()->create())
            ->getJson('/api/books');

        $response->assertOk()
            ->assertJsonCount(5, 'data');
    }

    public function test_reject_unauthenticated(): void
    {
        $this->getJson('/api/books')
            ->assertUnauthorized();
    }

    public function test_submit_order(): void
    {
        $book = Book::factory()->create(['stock' => 10]);
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/orders/submit', [
                'bookID' => $book->id,
                'amount' => 2,
            ])
            ->assertOk()
            ->assertJson(['status' => 'Confirmed']);

        $this->assertDatabaseHas('books', [
            'id' => $book->id, 'stock' => 8,
        ]);
    }
}
```

### Perbandingan Testing

| Fitur | CAP | Laravel |
|-------|-----|---------|
| **Framework** | Jest / Mocha + `cds.test()` | PHPUnit + Laravel TestCase |
| **In-memory DB** | `--in-memory` flag | `RefreshDatabase` trait |
| **Test server** | Auto (cds.test auto-start) | Auto (Laravel test harness) |
| **Auth mock** | `{ auth: { username, password } }` | `actingAs(User::factory())` |
| **Factory** | CSV seed data | Model Factories (Faker) |
| **DB assertions** | CQL queries | `assertDatabaseHas()` |
| **API test** | `GET()`, `POST()` helpers | `getJson()`, `postJson()` |

---

## 12. Deployment

### CAP — MTA + BTP Cloud Foundry

```yaml
# mta.yaml
_schema-version: '3.1'
ID: bookshop
version: 1.0.0

modules:
  - name: bookshop-srv           # ← CAP backend
    type: nodejs
    path: gen/srv
    requires:
      - name: bookshop-db        # ← HANA HDI
      - name: bookshop-auth      # ← XSUAA

  - name: bookshop-db-deployer   # ← DB migration
    type: hdb
    path: gen/db

  - name: bookshop               # ← Approuter (UI)
    type: approuter.nodejs
    requires:
      - name: bookshop-auth

resources:
  - name: bookshop-db
    type: com.sap.xs.hdi-container
  - name: bookshop-auth
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
```

```bash
# Deploy ke BTP
cds build --production    # Generate db/ dan srv/ artifacts
mbt build                 # Build MTA archive
cf deploy mta_archives/bookshop_1.0.0.mtar
```

### Laravel — Multiple Options

```bash
# Option 1: Traditional server
ssh production
cd /var/www/bookshop
git pull origin main
composer install --no-dev
php artisan migrate --force
php artisan config:cache
php artisan route:cache
sudo systemctl restart php-fpm

# Option 2: Laravel Forge (managed)
# Push ke git → Forge auto-deploy

# Option 3: Laravel Vapor (serverless AWS)
vapor deploy production

# Option 4: Docker
docker build -t bookshop .
docker push registry/bookshop
kubectl apply -f k8s/deployment.yaml
```

### Perbandingan Deployment

| Aspek | CAP + BTP | Laravel |
|-------|-----------|---------|
| **Target** | SAP BTP (CF/Kyma) | Any server / cloud |
| **Descriptor** | `mta.yaml` (MTA) | `.env` + deployment scripts |
| **DB migration** | Auto (`hdb` module) | `php artisan migrate` |
| **Build tool** | `mbt build` → `.mtar` | Composer + build scripts |
| **CI/CD** | SAP CI/CD Service / GitHub Actions | GitHub Actions / GitLab CI |
| **Serverless** | BTP Kyma (K8s) | Vapor (AWS Lambda) |
| **Scaling** | CF auto-scale | Manual / Forge / Vapor |
| **Cost** | SAP BTP license ($$$$) | Server cost only ($) |
| **Vendor lock-in** | Moderate-High (SAP ecosystem) | Minimal |

---

## 13. CLI Commands

| Tugas | CAP (`cds`) | Laravel (`artisan`) |
|-------|-------------|---------------------|
| **Init project** | `cds init bookshop` | `composer create-project laravel/laravel bookshop` |
| **Run dev server** | `cds watch` | `php artisan serve` |
| **Generate model** | Tulis di `schema.cds` | `php artisan make:model Book -mfc` |
| **Generate controller** | Auto dari CDS | `php artisan make:controller BookController --api` |
| **Generate migration** | Auto dari CDS | `php artisan make:migration create_books_table` |
| **Run migration** | `cds deploy` | `php artisan migrate` |
| **Seed data** | CSV files (auto) | `php artisan db:seed` |
| **Run tests** | `npx jest` | `php artisan test` |
| **Build production** | `cds build --production` | `composer install --no-dev` |
| **Interactive console** | `cds repl` | `php artisan tinker` |
| **List routes** | Lihat `$metadata` | `php artisan route:list` |
| **Clear cache** | N/A (auto) | `php artisan cache:clear` |
| **Add module** | `cds add hana,xsuaa,approuter` | `composer require package` |
| **Generate auth** | `cds add xsuaa` | `php artisan breeze:install` |

---

## 14. Ekosistem & Integrasi

### CAP Ecosystem

```
┌──────────────────────────────────────────────────────────┐
│                    SAP BTP Platform                       │
├────────────┬────────────┬────────────┬───────────────────┤
│  HANA Cloud│  XSUAA/IAS │  SAP Event │  SAP Integration  │
│  (Database)│  (Auth)    │  Mesh      │  Suite             │
├────────────┼────────────┼────────────┼───────────────────┤
│  Fiori     │  Work Zone │  Cloud     │  S/4HANA          │
│  Elements  │  (Portal)  │  Connector │  Extension         │
├────────────┼────────────┼────────────┼───────────────────┤
│  SAP AI    │  Document  │  SAP Build │  Business          │
│  Core      │  Management│  Apps      │  Rules             │
└────────────┴────────────┴────────────┴───────────────────┘
```

### Laravel Ecosystem

```
┌──────────────────────────────────────────────────────────┐
│                  Laravel Ecosystem                        │
├────────────┬────────────┬────────────┬───────────────────┤
│  Forge     │  Vapor     │  Nova      │  Spark             │
│  (Deploy)  │  (Serverless)│ (Admin)  │  (SaaS Billing)   │
├────────────┼────────────┼────────────┼───────────────────┤
│  Horizon   │  Telescope │  Sanctum   │  Socialite         │
│  (Queues)  │  (Debug)   │  (API Auth)│  (OAuth)           │
├────────────┼────────────┼────────────┼───────────────────┤
│  Livewire  │  Inertia   │  Cashier   │  Scout             │
│  (Reactive)│  (SPA)     │  (Payment) │  (Full-text search)│
├────────────┼────────────┼────────────┼───────────────────┤
│  Reverb    │  Pennant   │  Pulse     │  Pint              │
│  (WebSocket)│ (Feature  │  (Monitor) │  (Code Style)      │
│            │   Flags)   │            │                    │
└────────────┴────────────┴────────────┴───────────────────┘
```

### Perbandingan Ekosistem

| Aspek | CAP | Laravel |
|-------|-----|---------|
| **Admin panel** | Fiori Elements (auto) | Nova ($$$) / Filament (free) |
| **Queue/Jobs** | SAP Event Mesh | Horizon + Redis/SQS |
| **Full-text search** | HANA full-text index | Scout + Algolia/Meilisearch |
| **Real-time** | SAP Event Mesh / WebSocket | Reverb / Pusher |
| **Payment** | SAP Billing | Cashier (Stripe/Paddle) |
| **File storage** | SAP Document Management | Flysystem (S3/local) |
| **Email** | SAP BTP Mail | Built-in Mailables |
| **Debug** | CDS REPL + logs | Telescope + Debugbar |
| **Community packages** | ~100 (niche SAP) | ~300,000+ (Packagist) |
| **Community size** | Enterprise SAP consultants | Massive global community |

---

## 15. Performance & Scalability

| Aspek | CAP (Node.js) | Laravel (PHP) |
|-------|---------------|---------------|
| **Runtime** | V8 Engine (event loop) | PHP-FPM (request-response) |
| **Concurrency** | Non-blocking async I/O | Process-per-request (+ Octane) |
| **ORM overhead** | CQL → optimized SQL | Eloquent → moderate overhead |
| **Caching** | Built-in query cache | Redis / Memcached |
| **Connection pooling** | HANA native pooling | Manual config |
| **Horizontal scaling** | CF auto-scaler | Load balancer + multiple instances |
| **Memory** | ~50-100MB per instance | ~30-50MB per request |
| **Cold start** | Moderate (Node.js) | Fast (PHP-FPM warm) |
| **Octane equivalent** | Default (always running) | Laravel Octane (Swoole/RoadRunner) |

---

## 16. Learning Curve

### Dari Nol ke Produktif

```
Waktu estimasi (developer berpengalaman web):

CAP:
├── Week 1-2:  CDS basics, cds watch, CRUD otomatis          ✅ Bisa bikin app sederhana
├── Week 3-4:  Event handlers, custom logic, testing          ✅ Bisa bikin business app
├── Week 5-8:  HANA Cloud, XSUAA, MTA deployment             ⚠️  BTP learning curve tinggi
├── Week 9-12: Fiori Elements, annotations, Work Zone         ⚠️  SAP UI paradigm berbeda
└── Month 4+:  S/4HANA extension, Event Mesh, multi-tenancy  🔴 Deep SAP knowledge needed

Laravel:
├── Week 1:    Routes, controllers, Eloquent, Blade           ✅ Bisa bikin app sederhana
├── Week 2-3:  Auth, middleware, API resources, testing        ✅ Bisa bikin production app
├── Week 4-6:  Queues, events, notification, caching          ✅ Advanced features
├── Week 7-8:  Forge/Vapor deploy, CI/CD                      ✅ Production deployment
└── Month 3+:  Microservices, DDD, event sourcing             🔴 Architecture decisions
```

### Prerequisite Knowledge

| Perlu Tahu | CAP | Laravel |
|------------|-----|---------|
| **Bahasa utama** | JavaScript/TypeScript | PHP |
| **SQL** | Basic (CDS abstracts it) | Moderate |
| **HTTP/REST** | Basic (auto-generated) | Deep understanding |
| **OData** | Perlu paham basics | Tidak perlu |
| **SAP ecosystem** | Wajib (BTP, HANA, XSUAA) | Tidak perlu |
| **Cloud Foundry** | Perlu untuk deploy | Tidak perlu |
| **HTML/CSS** | Optional (Fiori auto) | Perlu untuk views |

---

## 17. Kapan Pakai Yang Mana?

### Pakai CAP Ketika:

| Skenario | Alasan |
|----------|--------|
| ✅ Extension S/4HANA | CAP = native extension framework |
| ✅ Enterprise SAP landscape | Integrasi HANA, XSUAA, Event Mesh seamless |
| ✅ Side-by-side app di BTP | MTA deployment, managed services |
| ✅ OData consumer (Fiori, SAP Build Apps) | Auto OData v4 + annotations |
| ✅ Multi-tenant SaaS di BTP | MTX built-in |
| ✅ Perusahaan sudah pakai SAP | Ecosystem alignment |
| ✅ Tim SAP consultant | Familiar CDS, ABAP mindset |

### Pakai Laravel Ketika:

| Skenario | Alasan |
|----------|--------|
| ✅ Web app umum / SaaS | Fleksibel, cepat develop |
| ✅ Startup / MVP | Open source, low cost, banyak resource |
| ✅ REST API backend | Mature, well-documented |
| ✅ E-commerce, CMS, social media | Ecosystem kaya (Cashier, Scout, etc.) |
| ✅ Custom UI/UX yang unik | Full control over frontend |
| ✅ Tim PHP / web developer | Familiar ecosystem |
| ✅ Multi-cloud / vendor agnostic | Deploy dimana saja |
| ✅ Budget terbatas | MIT license, cheap hosting |

### Jangan Pakai CAP Ketika:

- ❌ Non-SAP project (over-engineering)
- ❌ Need custom REST API design (OData terlalu rigid)
- ❌ Budget kecil (BTP license mahal)
- ❌ Tim tidak familiar SAP ecosystem

### Jangan Pakai Laravel Ketika:

- ❌ SAP extension project (reinventing the wheel)
- ❌ Heavy real-time / WebSocket (pakai Go/Elixir)
- ❌ Microservices at scale (pakai Spring Boot / Node.js)
- ❌ Data-intensive computation (pakai Python/Rust)

---

## 18. Side-by-Side Code Comparison (Bookshop)

### Skenario: "Buat API Bookshop dengan 5 entity, auth, filtering, sorting, pagination"

#### CAP — Total ~80 lines

```cds
// db/schema.cds (30 lines)
namespace bookshop;
using { cuid, managed, Currency } from '@sap/cds/common';

entity Books : cuid, managed {
    title  : String(150);
    price  : Decimal(10,2);
    stock  : Integer;
    author : Association to Authors;
    genre  : Association to Genres;
    reviews: Composition of many Reviews on reviews.book = $self;
}
entity Authors : cuid, managed { name: String(100); books: Association to many Books on books.author = $self; }
entity Genres  { key code: String(4); name: String(100); }
entity Reviews : cuid, managed { rating: Integer; text: String(500); book: Association to Books; }
entity Orders  : cuid, managed { buyer: String; items: Composition of many OrderItems on items.parent = $self; }
entity OrderItems : cuid { book: Association to Books; quantity: Integer; parent: Association to Orders; }
```

```cds
// srv/catalog.cds (15 lines)
using { bookshop } from '../db/schema';
@requires: 'authenticated-user'
service CatalogService @(path:'/api') {
    @readonly entity Books as projection on bookshop.Books;
    @readonly entity Authors as projection on bookshop.Authors;
    action submitOrder(bookID: UUID, amount: Integer) returns { status: String };
}
```

```javascript
// srv/catalog.js (25 lines)
module.exports = class CatalogService extends require('@sap/cds').ApplicationService {
    async init() {
        this.on('submitOrder', async req => {
            const { bookID, amount } = req.data;
            const book = await SELECT.one('bookshop.Books').where({ ID: bookID });
            if (book.stock < amount) req.reject(409, 'Out of stock');
            await UPDATE('bookshop.Books').set({ stock: { '-=': amount } }).where({ ID: bookID });
            return { status: 'Confirmed' };
        });
        await super.init();
    }
};
```

```csv
// db/data/bookshop-Books.csv (auto-seed)
ID;title;price;stock;author_ID
1;Clean Code;39.99;50;a1
2;The Pragmatic Programmer;49.99;30;a2
```

**Done.** Full OData API with `$filter`, `$orderby`, `$top`, `$skip`, `$expand`, `$search`, auth, metadata — semua otomatis.

---

#### Laravel — Total ~250+ lines

```bash
php artisan make:model Book -mfcr
php artisan make:model Author -mfcr
php artisan make:model Genre -m
php artisan make:model Review -mf
php artisan make:model Order -mfcr
php artisan make:model OrderItem -m
# = 6 models + 6 migrations + 4 factories + 3 controllers + 3 resources
# = ~20 files generated, each needs manual editing
```

*Kemudian tulis manual: migration schemas, model relationships, fillable, controller CRUD methods, Form Requests, API Resources, routes, seeders...*

**Estimasi: 250-400 lines of code across 20+ files.**

---

## 19. Kesimpulan

```
┌─────────────────────────────────────────────────────────────────┐
│                    FINAL VERDICT                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CAP  = Framework TERBAIK untuk ekosistem SAP                   │
│          → Auto OData, HANA native, BTP integration              │
│          → Enterprise-grade dari hari pertama                    │
│          → Trade-off: vendor lock-in + biaya tinggi              │
│                                                                  │
│  Laravel = Framework TERBAIK untuk web development umum          │
│          → Fleksibel, community besar, open source               │
│          → Dari MVP sampai production cepat                      │
│          → Trade-off: manual setup untuk enterprise features     │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Keduanya EXCELLENT framework.                                   │
│  Pilihan tergantung pada:                                        │
│                                                                  │
│  🏢 Perusahaan SAP?          → CAP                              │
│  🌐 Web app umum?            → Laravel                           │
│  💰 Budget terbatas?          → Laravel                           │
│  🔗 Integrasi S/4HANA?       → CAP                              │
│  🚀 Startup MVP?             → Laravel                           │
│  🏗️  Enterprise SaaS di BTP? → CAP                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

> **Wahyu Amaldi** — Technical Lead SAP & Full Stack Development
> SAP Certified — BTP, ABAP, Fiori, BDC | Tel: 0881 0805 34116