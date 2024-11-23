import { JettonMaster } from '../wrappers/JettonMaster';
import { JettonDefaultWallet } from '../wrappers/JettonWallet';
import { NetworkProvider } from '@ton/blueprint';
import { Dictionary, beginCell, Cell } from '@ton/core';
import { toNano } from '@ton/ton';
import { buildOnchainMetadata } from './utils/helpers';

export function JettonContent(): Cell {
    const jettonParams = {
        name: 'Ikigai USDg',
        description: 'Ikigai Synthetic Dollar USDg',
        symbol: 'USDg',
        // image: 'https://cdn.coinranking.com/Djlyf7pV3/yTY6wAIV_400x400.PNG',
        // image: 'https://cdn.coinranking.com/Djlyf7pV3/yTY6wAIV_400x400.PNG',
        image: 'https://pbs.twimg.com/profile_images/1842139274554003456/OwAzS3_a_400x400.jpg',
    };
    let content = buildOnchainMetadata(jettonParams);
    return content;
}

export async function run(provider: NetworkProvider) {
    const default_content = await JettonContent();

    let jettonMaster = provider.open(await JettonMaster.fromInit(provider.sender().address!!, default_content));

    // await jettonMaster.send(
    //     provider.sender(),
    //     {
    //         value: toNano('0.05'),
    //     },
    //     {
    //         $$type: 'Mint',
    //         amount: toNano(888),
    //         receiver: provider.sender().address!!,
    //     },
    // );

    await jettonMaster.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        // 'Mint: 100',
        {
            $$type: 'Deploy',
            queryId: 0n,
        },
    );

    await provider.waitForDeploy(jettonMaster.address);

    // let receiverWalletContract = provider.open(
    //     await JettonDefaultWallet.fromInit(
    //         jettonMaster.address,
    //         Address.parse('0QBNWh2vUbs2e2eFUBKhNQyoP33NHvo6r8ZIxfeP4RGQGJr2'),
    //     ),
    // );
}
