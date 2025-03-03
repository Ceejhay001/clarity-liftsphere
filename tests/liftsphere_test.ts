Clarinet.test({
    name: "Validates workout input properly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        // Test invalid weights (zero or negative)
        let block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'log-workout', [
                types.uint(0),
                types.list([types.uint(3)]),
                types.list([types.uint(10)]),
                types.list([types.uint(0)])  // Invalid weight
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(103));

        // Test mismatched lengths
        block = chain.mineBlock([
            Tx.contractCall('liftsphere', 'log-workout', [
                types.uint(0),
                types.list([types.uint(3), types.uint(3)]),
                types.list([types.uint(10)]),
                types.list([types.uint(225)])
            ], deployer.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(103));
    }
});

[... previous tests remain the same ...]
