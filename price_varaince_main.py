from config.settings import get_settings

from database.mysql_connection import (
    create_mysql_engine,
    test_connection,
)

from database.duckdb_connection import (
    DuckDBManager,
)

from database.duckdb_loader import (
    register_dataframe,
)

from readers.ap_reader import (
    APReader,
)

from readers.novus_reader import (
    NovusReader,
)

from preparation.ap_preparation import (
    APPreparation,
)

from preparation.novus_preparation import (
    NovusPreparation,
)
from config.business_rules import CONTRACT_HIERARCHY

from database.duckdb_loader import (
    register_dataframe,
    register_contract_hierarchy,
)

from matching.price_matching import (
    PriceMatching,
)


INVOICE_TABLE = "Invoice_detail_inmar"

NOVUS_TABLE = (
    "HunterAI CCHS_ContractPriceRepository_post2025_20260625_2"
)


def main():

    settings = get_settings()

    print("=" * 70)
    print("PRICE VARIANCE RECOVERY")
    print("=" * 70)

    mysql_engine = create_mysql_engine(
        settings.database
    )

    duckdb_manager = DuckDBManager(
        database_path=settings.duckdb.database_path,
        threads=settings.duckdb.threads,
    )

    try:

        # --------------------------------------------------
        # MySQL
        # --------------------------------------------------

        test_connection(
            mysql_engine
        )

        # --------------------------------------------------
        # Step 3 - AP
        # --------------------------------------------------

        print("\nLoading AP...")

        ap_reader = APReader(
            mysql_engine,
            INVOICE_TABLE,
        )

        ap = ap_reader.read(
            settings.analysis.start_date,
            settings.analysis.end_date,
        )

        print(
            f"AP rows: {len(ap):,}"
        )

        # --------------------------------------------------
        # Step 4 - MPNs
        # --------------------------------------------------

        mpns = (
            ap["MPN"]
            .dropna()
            .astype(str)
            .str.strip()
            .unique()
            .tolist()
        )

        print(
            f"Distinct MPNs: {len(mpns):,}"
        )

        # --------------------------------------------------
        # Step 4 - Novus
        # --------------------------------------------------

        print("\nLoading Novus...")

        novus_reader = NovusReader(
            mysql_engine,
            NOVUS_TABLE,
            batch_size=1000,
        )

        novus = novus_reader.read(
            mpns
        )

        print(
            f"Novus rows: {len(novus):,}"
        )

        # --------------------------------------------------
        # Step 5 - DuckDB
        # --------------------------------------------------

        print("\nStarting DuckDB...")

        connection = (
            duckdb_manager.connect()
        )

        register_dataframe(
            connection,
            "ap",
            ap,
        )

        register_dataframe(
            connection,
            "novus",
            novus,
        )

        # --------------------------------------------------
        # Step 6 - Preparation
        # --------------------------------------------------

        print("\nPreparing AP...")

        APPreparation(
            connection
        ).execute()

        print(
            "AP preparation completed."
        )

        print("\nPreparing Novus...")

        NovusPreparation(
            connection
        ).execute()

        print(
            "Novus preparation completed."
        )
        
        

        # --------------------------------------------------
        # Step 7
        # --------------------------------------------------

        print(
            "\nStep 7 - Price matching pending..."
        )

        # --------------------------------------------------
        # Step 8
        # --------------------------------------------------

        print(
            "Step 8 - enriched_ap pending..."
        )

        # --------------------------------------------------
        # Step 9
        # --------------------------------------------------

        print(
            "Step 9 - recovery evidence pending..."
        )

        # --------------------------------------------------
        # Step 10
        # --------------------------------------------------

        print(
            "Step 10 - product review pending..."
        )

    finally:

        duckdb_manager.close()

        mysql_engine.dispose()

        print(
            "\nConnections closed."
        )


if __name__ == "__main__":
    main()