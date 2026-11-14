CREATE TABLE "invoice_settlements" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"invoice_id" uuid NOT NULL,
	"counter_invoice_id" uuid NOT NULL,
	"settlement_id" uuid DEFAULT gen_random_uuid() NOT NULL,
	"date" date NOT NULL,
	"amount" integer NOT NULL,
	"note" text DEFAULT '' NOT NULL,
	"reverses_id" uuid,
	"created_by" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "invoice_settlements_two" CHECK ("invoice_settlements"."invoice_id" <> "invoice_settlements"."counter_invoice_id"),
	CONSTRAINT "invoice_settlements_amount" CHECK ("invoice_settlements"."amount" <> 0)
);
--> statement-breakpoint
ALTER TABLE "invoice_settlements" ADD CONSTRAINT "invoice_settlements_invoice_id_invoices_id_fk" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoices"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice_settlements" ADD CONSTRAINT "invoice_settlements_counter_invoice_id_invoices_id_fk" FOREIGN KEY ("counter_invoice_id") REFERENCES "public"."invoices"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice_settlements" ADD CONSTRAINT "invoice_settlements_reverses_fk" FOREIGN KEY ("reverses_id") REFERENCES "public"."invoice_settlements"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "invoice_settlements_invoice" ON "invoice_settlements" USING btree ("invoice_id");--> statement-breakpoint
CREATE INDEX "invoice_settlements_counter" ON "invoice_settlements" USING btree ("counter_invoice_id");--> statement-breakpoint
CREATE INDEX "invoice_settlements_settlement" ON "invoice_settlements" USING btree ("settlement_id");--> statement-breakpoint
CREATE UNIQUE INDEX "invoice_settlements_settlement_invoice" ON "invoice_settlements" USING btree ("settlement_id","invoice_id");--> statement-breakpoint
CREATE UNIQUE INDEX "invoice_settlements_reverses" ON "invoice_settlements" USING btree ("reverses_id");

-- Verrechnungen mit einer Kundenkorrektur sind Buchungen ohne Geldfluss: nur anhängen, Aufhebung als Gegenzeile
-- (reverses_id), nie ändern.
CREATE TRIGGER invoice_settlements_append_only BEFORE UPDATE OR DELETE ON invoice_settlements
  FOR EACH ROW EXECUTE FUNCTION haben_append_only();
--> statement-breakpoint
CREATE TRIGGER invoice_settlements_audit AFTER INSERT ON invoice_settlements
  FOR EACH ROW EXECUTE FUNCTION haben_audit();
--> statement-breakpoint
CREATE TRIGGER invoice_settlements_no_truncate BEFORE TRUNCATE ON invoice_settlements
  FOR EACH STATEMENT EXECUTE FUNCTION haben_reject_truncate();
