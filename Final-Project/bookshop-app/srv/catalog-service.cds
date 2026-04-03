using { com.tecrise.bookshop as db } from '../db/schema';

// ============================================
// CATALOG SERVICE — Public facing API
// ============================================
@requires: 'authenticated-user'
service CatalogService @(path: '/catalog') {

    @readonly
    entity Books as projection on db.Books {
        *,
        author.name as authorName,
        case
            when stock >= 20 then 3  // Green  (Positive)
            when stock >  0  then 2  // Orange (Warning)
            else                 1   // Red    (Negative)
        end as stockCriticality : Integer
    } excluding { orders };

    @readonly
    entity Authors as projection on db.Authors;

    @readonly
    entity Genres as projection on db.Genres;

    // Read reviews
    @readonly
    entity Reviews as projection on db.Reviews;

    // Actions
    @(requires: 'write')
    action submitOrder(bookID: UUID, amount: Integer) returns {
        orderID : UUID;
        status  : String;
        message : String;
    };

    // Functions
    function countBooksForAuthor(authorID: UUID) returns Integer;
    function getAverageRating(bookID: UUID) returns Decimal;
}

// ============================================
// ADMIN SERVICE — Administrative access
// ============================================
@requires: 'admin'
service AdminService @(path: '/admin') {
    entity Books      as projection on db.Books;
    entity Authors    as projection on db.Authors;
    entity Genres     as projection on db.Genres;
    entity Orders     as projection on db.Orders;
    entity OrderItems as projection on db.OrderItems;
    entity Reviews    as projection on db.Reviews;
}
