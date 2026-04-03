namespace com.tecrise.bookshop;

using { Currency, managed, cuid, CodeList } from '@sap/cds/common';

// ============================================
// ENTITY: Authors
// ============================================
entity Authors : cuid, managed {
    name         : String(100) not null;
    dateOfBirth  : Date;
    dateOfDeath  : Date;
    placeOfBirth : String(100);
    placeOfDeath : String(100);
    books        : Association to many Books on books.author = $self;
}

// ============================================
// ENTITY: Genres (CodeList — master data)
// ============================================
entity Genres : CodeList {
    key code    : String(4);
    parent      : Association to Genres;
    children    : Composition of many Genres on children.parent = $self;
}

// ============================================
// ENTITY: Books
// ============================================
entity Books : cuid, managed {
    title        : String(150) not null;
    descr        : String(1000);
    author       : Association to Authors;
    genre        : Association to Genres;
    stock        : Integer default 0;
    price        : Decimal(10,2);
    currency     : Currency;
    orders       : Association to many OrderItems on orders.book = $self;
    reviews      : Composition of many Reviews on reviews.book = $self;
}

// ============================================
// ENTITY: Orders
// ============================================
entity Orders : cuid, managed {
    OrderNo      : String(20)  @title: 'Order Number';
    buyer        : String(100) @title: 'Buyer Name';
    currency     : Currency;
    items        : Composition of many OrderItems on items.parent = $self;
}

entity OrderItems : cuid {
    parent       : Association to Orders;
    book         : Association to Books;
    amount       : Integer;
    netAmount    : Decimal(10,2);
}

// ============================================
// ENTITY: Reviews
// ============================================
entity Reviews : cuid, managed {
    book         : Association to Books;
    reviewer     : String(100);
    rating       : Integer @assert.range: [1, 5];
    title        : String(100);
    text         : String(1000);
}
