const cds = require('@sap/cds');

module.exports = class CatalogService extends cds.ApplicationService {

    async init() {
        const db = await cds.connect.to('db');
        const { Books, OrderItems, Orders, Reviews } = db.entities('com.tecrise.bookshop');

        // ---- Validation: Before CREATE Books ----
        this.before('CREATE', 'Books', (req) => {
            const { title, price } = req.data;
            if (!title?.trim()) req.reject(400, 'Book title is required');
            if (price !== undefined && price < 0) req.reject(400, 'Price cannot be negative');
        });

        // ---- After READ: Add computed field ----
        this.after('READ', 'Books', (results) => {
            const books = Array.isArray(results) ? results : [results];
            books.forEach(book => {
                if (book.stock !== undefined) {
                    book.stockStatus = book.stock > 10 ? 'High'
                        : book.stock > 0 ? 'Low' : 'Out of Stock';
                }
            });
        });

        // ---- ACTION: submitOrder ----
        this.on('submitOrder', async (req) => {
            const { bookID, amount } = req.data;
            if (!bookID) req.reject(400, 'bookID is required');
            if (!amount || amount <= 0) req.reject(400, 'amount must be a positive integer');

            const book = await SELECT.one(Books).where({ ID: bookID });
            if (!book) req.reject(404, `Book ${bookID} not found`);
            if (book.stock < amount) {
                req.reject(409, `Insufficient stock. Available: ${book.stock}, Requested: ${amount}`);
            }

            // Reduce stock
            await UPDATE(Books)
                .set({ stock: book.stock - amount })
                .where({ ID: bookID });

            // Create an order record
            const orderID = cds.utils.uuid();
            await INSERT.into(Orders).entries({
                ID      : orderID,
                OrderNo : `ORD-${Date.now()}`,
                buyer   : req.user?.id || 'anonymous',
                currency_code: book.currency_code
            });

            await INSERT.into(OrderItems).entries({
                ID       : cds.utils.uuid(),
                parent_ID: orderID,
                book_ID  : bookID,
                amount   : amount,
                netAmount: (book.price || 0) * amount
            });

            return {
                orderID,
                status : 'CONFIRMED',
                message: `Order for ${amount} x "${book.title}" confirmed.`
            };
        });

        // ---- FUNCTION: countBooksForAuthor ----
        this.on('countBooksForAuthor', async (req) => {
            const { authorID } = req.data;
            const result = await SELECT.from(Books).where({ author_ID: authorID });
            return result.length;
        });

        // ---- FUNCTION: getAverageRating ----
        this.on('getAverageRating', async (req) => {
            const { bookID } = req.data;
            const rows = await SELECT.from(Reviews)
                .columns('rating')
                .where({ book_ID: bookID });
            if (!rows.length) return null;
            const avg = rows.reduce((sum, r) => sum + r.rating, 0) / rows.length;
            return Math.round(avg * 10) / 10;
        });

        return super.init();
    }
};
