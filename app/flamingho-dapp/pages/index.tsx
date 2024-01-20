"use client"
import { useEffect, useState } from "react";
import Image from "next/image";
import { 
  useAccount, useNetwork, 
  usePrepareContractWrite, 
  useContractWrite, 
  useWaitForTransaction,
  useContractRead
} from "wagmi";
import { optimismGoerli, sepolia } from "wagmi/chains";
import { ConnectKitButton, ConnectKitProvider } from "connectkit";
import { fsAbi } from "../utils/fsAbi";
import { fmAbi } from "../utils/fmAbi";
import { erc20Abi } from "../utils/erc20Abi";
import { Inter } from "next/font/google";
import { Birthstone } from "next/font/google";

const inter = Inter({ subsets: ["latin"] });
const birthstone = Birthstone({ subsets: ["latin"], weight: ["400"] });

const GHO_TOKEN = "0xEBa15c28A6570407785D4547f191e92ea91F42e4";
const flaminGHO_TOKEN = "0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae";
const USDC_SEPOLIA = "0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8";
const USDC_OPTIMISM_GOERLI = "0xe05606174bac4A6364B31bd0eCA4bf4dD368f8C6";
const FACILITATOR_STABLE = "0x4418E27448F6d1c87778543EC7F0A77c27202e75";
const FACILITATOR_MULTICHAIN = "0x12fC262Bd99Cb3f8A1cEdb58bf9A760Eea3427bC";
const fee = 420;
const MAX_UINT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";

export default function Home() {
  const [amount, setAmount] = useState<number>(0);  
  const [message, setMessage] = useState<string>();
  const [refresh, setRefresh] = useState<number>(0);
  const [errorMessage, setErrorMessage] = useState<string>();
  const [currentAction, setCurrentAction] = useState<string>();
  
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();

  const { data: balanceUSDCSepolia, refetch: refetchUSDCSep } = useContractRead({
    address: USDC_SEPOLIA,
    abi: erc20Abi,
    chainId: sepolia.id,
    functionName: 'balanceOf',
    enabled: chain?.id === sepolia.id,
    args: [address]
  });
  
  const { data: balanceUSDCOpt, refetch: refetchUSDCOpt } = useContractRead({
    address: USDC_OPTIMISM_GOERLI,
    abi: erc20Abi,
    chainId: optimismGoerli.id,
    functionName: 'balanceOf',
    enabled: chain?.id === optimismGoerli.id,
    args: [address]
  });
  
  const { data: balanceGHO, refetch: refetchGHO } = useContractRead({
    address: GHO_TOKEN,
    abi: erc20Abi,
    chainId: sepolia.id,
    functionName: 'balanceOf',
    enabled: chain?.id === sepolia.id,
    args: [address]
  });
  
  const { data: balanceFlaminGHO, refetch: refetchFlaminGHO } = useContractRead({
    address: flaminGHO_TOKEN,
    abi: erc20Abi,
    chainId: optimismGoerli.id,
    functionName: 'balanceOf',
    enabled: chain?.id === optimismGoerli.id,
    args: [address]
  });
  
  const { data: allowanceUSDCSepolia, refetch: refetchAllowanceUSDCSep } = useContractRead({
    address: USDC_SEPOLIA,
    abi: erc20Abi,
    chainId: sepolia.id,
    functionName: 'allowance',
    //watch: true,
    enabled: chain?.id === sepolia.id,
    args: [address, FACILITATOR_STABLE]
  });
  
  const { data: allowanceUSDCOpt, refetch: refetchAllowanceUSDCOpt } = useContractRead({
    address: USDC_OPTIMISM_GOERLI,
    abi: erc20Abi,
    chainId: optimismGoerli.id,
    functionName: 'allowance',
    //watch: true,
    enabled: chain?.id === optimismGoerli.id,
    args: [address, FACILITATOR_MULTICHAIN]
  });
  
  const { data: allowanceGHO, refetch: refetchAllowanceGHO } = useContractRead({
    address: GHO_TOKEN,
    abi: erc20Abi,
    chainId: sepolia.id,
    functionName: 'allowance',
    //watch: true,
    enabled: chain?.id === sepolia.id,
    args: [address, FACILITATOR_STABLE]
  });
  
  const { data: allowanceFlaminGHO, refetch: refetchAllowanceFGHO } = useContractRead({
    address: flaminGHO_TOKEN,
    abi: erc20Abi,
    chainId: optimismGoerli.id,
    functionName: 'allowance',
    //watch: true,
    enabled: chain?.id === optimismGoerli.id,
    args: [address, FACILITATOR_MULTICHAIN]
  });
  
  const { data: bucketGHO, refetch: refetchBucketGHO } = useContractRead({
    address: FACILITATOR_STABLE,
    abi: fsAbi,
    chainId: sepolia.id,
    functionName: 'bucket',
    enabled: chain?.id === sepolia.id,
  }); 

  const { data: bucketFlaminGHO, refetch: refetchBucketFGHO } = useContractRead({
    address: FACILITATOR_MULTICHAIN,
    abi: fmAbi,
    chainId: optimismGoerli.id,
    functionName: 'bucket',
    enabled: chain?.id === optimismGoerli.id,
  }); 

  
  const { config: configUSDCSepoliaApprove } = usePrepareContractWrite({
    address: USDC_SEPOLIA,
    abi: erc20Abi,
    functionName: 'approve',
    args: [FACILITATOR_STABLE, MAX_UINT],
    chainId: sepolia.id,
    account: address,
    enabled: amount !== 0 && chain?.id === sepolia.id && allowanceUSDCSepolia as number < amount,
    onError(error) {
      setErrorMessage(error.message);
    }
  });  
  
  const { config: configUSDCOptApprove } = usePrepareContractWrite({
    address: USDC_OPTIMISM_GOERLI,
    abi: erc20Abi,
    functionName: 'approve',
    args: [FACILITATOR_MULTICHAIN, MAX_UINT],
    chainId: optimismGoerli.id,
    account: address,
    enabled: amount !== 0 && chain?.id === optimismGoerli.id && allowanceUSDCOpt as number < amount,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { config: configGhoApprove } = usePrepareContractWrite({
    address: GHO_TOKEN,
    abi: erc20Abi,
    functionName: 'approve',
    args: [FACILITATOR_STABLE, MAX_UINT],
    chainId: sepolia.id,
    account: address,
    enabled: amount !== 0 && chain?.id === sepolia.id && allowanceGHO as number < fee,
    onError(error) {
      setErrorMessage(error.message);
    }
  });  
  
  const { config: configFlaminGhoApprove } = usePrepareContractWrite({
    address: flaminGHO_TOKEN,
    abi: erc20Abi,
    functionName: 'approve',
    args: [FACILITATOR_MULTICHAIN, MAX_UINT],
    chainId: optimismGoerli.id,
    account: address,
    enabled: amount !== 0 && chain?.id === optimismGoerli.id && allowanceFlaminGHO as number < fee,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { config: configGhoBuy } = usePrepareContractWrite({
    address: FACILITATOR_STABLE,
    abi: fsAbi,
    functionName: 'buy',
    args: [amount],
    chainId: sepolia.id,
    account: address,
    enabled: amount !== 0 && chain?.id === sepolia.id && allowanceUSDCSepolia as number >= amount && allowanceGHO as number >= fee,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { config: configGhoSell } = usePrepareContractWrite({
    address: FACILITATOR_STABLE,
    abi: fsAbi,
    functionName: 'sell',
    args: [amount],
    chainId: sepolia.id,
    account: address,
    enabled: amount !== 0 && chain?.id === sepolia.id && (bucketGHO as any)?.[1] as number >= amount,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { config: configFlaminGhoBuy } = usePrepareContractWrite({
    address: FACILITATOR_MULTICHAIN,
    abi: fmAbi,
    functionName: 'buy',
    args: [amount],
    chainId: optimismGoerli.id,
    account: address,
    enabled: amount !== 0 && chain?.id === optimismGoerli.id && allowanceFlaminGHO as number >= fee && allowanceUSDCOpt as number >= amount,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { config: configFlaminGhoSell } = usePrepareContractWrite({
    address: FACILITATOR_MULTICHAIN,
    abi: fmAbi,
    functionName: 'sell',
    args: [amount],
    chainId: optimismGoerli.id,
    account: address,
    enabled: amount !== 0 && chain?.id === optimismGoerli.id && (bucketFlaminGHO as any)?.[1] as number >= amount,
    onError(error) {
      setErrorMessage(error.message);
    }
  });
  
  const { 
    data: usdcSepoliaApproveData, 
    isLoading: isLoadingUsdcSepoliaApprove, 
    isSuccess: isSuccessUsdcSepoliaApprove, 
    write: writeUsdcSepoliaApprove
  } = useContractWrite({ 
    ...configUSDCSepoliaApprove,
    onSuccess(data) {
      onBuyGHOClick();
    }
  });
  
  const { 
    data: usdcOptApproveData, 
    isLoading: isLoadingUsdcOptApprove, 
    isSuccess: isSuccessUsdcOptApprove, 
    write: writeUsdcOptApprove
  } = useContractWrite({
    ...configUSDCOptApprove,
    onSuccess(data) {
      onBuyFlaminGHOClick();
    }
  });
  
  const { 
    data: ghoApproveData, 
    isLoading: isLoadingGhoApprove, 
    isSuccess: isSuccessGhoApprove, 
    write: writeGhoApprove
  } = useContractWrite({
    ...configGhoApprove,
    onSuccess(data) {
      if (currentAction === 'buy') {
        onBuyGHOClick();
      } else if (currentAction === 'sell') {
        onSellGHOClick();
      }
    }    
  });
  
  const { 
    data: flaminGhoApproveData, 
    isLoading: isLoadingFlaminGhoApprove, 
    isSuccess: isSuccessFlaminGhoApprove, 
    write: writeFlaminGhoApprove
  } = useContractWrite({
    ...configFlaminGhoApprove,
    onSuccess(data) {
      if (currentAction === 'buy') {
        onBuyFlaminGHOClick();
      } else if (currentAction === 'sell') {
        onSellFlaminGHOClick();
      }
    }     
  });
  
  const { 
    data: ghoBuyData, 
    isLoading: isLoadingGhoBuy, 
    isSuccess: isSuccessGhoBuy, 
    write: writeGhoBuy
  } = useContractWrite({
    ...configGhoBuy,
    onSuccess(data) {
      console.log(data)
    }
  });
  
  const { 
    data: ghoSellData, 
    isLoading: isLoadingGhoSell, 
    isSuccess: isSuccessGhoSell, 
    write: writeGhoSell
  } = useContractWrite(configGhoSell);
  
  const { 
    data: flaminGhoBuyData, 
    isLoading: isLoadingFlaminGhoBuy, 
    isSuccess: isSuccessFlaminGhoBuy, 
    write: writeFlaminGhoBuy
  } = useContractWrite({ 
    ...configFlaminGhoBuy,
    onSuccess(data) {
      console.log(data)
    }    
  });  

  const { 
    data: flaminGhoSellData, 
    isLoading: isLoadingFlaminGhoSell, 
    isSuccess: isSuccessFlaminGhoSell, 
    write: writeFlaminGhoSell
  } = useContractWrite(configFlaminGhoSell);
  
  const { data: txData, isError, isLoading } = useWaitForTransaction({
    hash: 
      usdcSepoliaApproveData?.hash || usdcOptApproveData?.hash ||
      ghoApproveData?.hash || flaminGhoApproveData?.hash ||
      ghoBuyData?.hash || ghoSellData?.hash 
      || flaminGhoBuyData?.hash || flaminGhoSellData?.hash,
    onSuccess(data) {
      onComplete();
    }
  });
  
  const onBuyGHOClick = () => {
    if (!amount || chain?.id !== sepolia.id) return;
    setCurrentAction('buy');
    
    console.log(allowanceUSDCSepolia);
    console.log(amount);
    console.log(allowanceGHO);
    console.log(fee);
    
    if (allowanceGHO as number < fee) {
      writeGhoApprove?.();
    } else if (allowanceUSDCSepolia as number < amount) {
      writeUsdcSepoliaApprove?.();
    } else {
      writeGhoBuy?.();    
    }
  }
  
  const onSellGHOClick = () => {
    if (!amount || chain?.id !== sepolia.id) return;
    setCurrentAction('sell');
    
    console.log((bucketGHO as any)?.[1]);
    console.log(amount);
    console.log(allowanceGHO);
    console.log(fee);
    
    if (allowanceGHO as number < amount + fee) {
      writeGhoApprove?.();
    } else {
      writeGhoSell?.();
    }
  }
  
  const onBuyFlaminGHOClick = () => {
    if (!amount || chain?.id !== optimismGoerli.id) return;
    setCurrentAction('buy');
    
    console.log(allowanceUSDCOpt);
    console.log(amount);    
    console.log(allowanceFlaminGHO);
    console.log(fee);
    
    if (allowanceFlaminGHO as number < fee) {
      writeFlaminGhoApprove?.();
    } else if (allowanceUSDCOpt as number < amount) {
      writeUsdcOptApprove?.();
    } else {
      writeFlaminGhoBuy?.();      
    }
  }
  
  const onSellFlaminGHOClick = () => {
    if (!amount || chain?.id !== optimismGoerli.id) return;
    setCurrentAction('sell');
    
    console.log((bucketFlaminGHO as any)?.[1]);
    console.log(amount);
    console.log(allowanceFlaminGHO);
    console.log(fee);
    
    if (allowanceFlaminGHO as number < amount + fee) {
      writeFlaminGhoApprove?.();
    } else {
      writeFlaminGhoSell?.();
    } 
  }
  
  const onComplete = () => {
    console.log('complete');
    
    refetchAllowanceUSDCOpt();
    refetchAllowanceUSDCSep(); 
    refetchAllowanceGHO();
    refetchAllowanceFGHO();
    refetchUSDCSep();
    refetchGHO();
    refetchUSDCSep();
    refetchUSDCOpt();
    refetchFlaminGHO();
  }
 
  useEffect(() => {
    if (isSuccessUsdcOptApprove || isSuccessUsdcSepoliaApprove) {
      setMessage(`Approved ${amount} USDC.`);
    }
  }, [isSuccessUsdcOptApprove, isSuccessUsdcSepoliaApprove]); 
  
  useEffect(() => {
    if (isSuccessGhoApprove) {
      setMessage(`Approved ${amount} GHO.`);
    }
  }, [isSuccessGhoApprove]);
  
  useEffect(() => {
    if (isSuccessFlaminGhoApprove) {
      setMessage(`Approved ${amount} fGHO.`);
    }
  }, [isSuccessFlaminGhoApprove]);

  useEffect(() => {
    if (isSuccessGhoBuy) {
      setMessage(`Bought ${amount} GHO.`);
    }
  }, [isSuccessGhoBuy]);
  
  useEffect(() => {
    if (isSuccessGhoSell) {
      setMessage(`Sold ${amount} GHO.`);
    }
  }, [isSuccessGhoSell]);
  
  useEffect(() => {
    if (isSuccessFlaminGhoBuy) {
      setMessage(`Bought ${amount} fGHO.`);
    }
  }, [isSuccessFlaminGhoBuy]);
  
  useEffect(() => {
    if (isSuccessFlaminGhoSell) {
      setMessage(`Sold ${amount} fGHO.`);
    }
  }, [isSuccessFlaminGhoSell]);
  
  
  
  const buttonStyle = "font-xl font-semibold rounded-xl px-6 py-4 disabled:opacity-[.6]";
  
  return (
    <main
      className={`flex min-h-screen flex-col flex-col-reverse items-center justify-between p-24 ${inter.className}`}
    >
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm lg:flex">
        <p className="fixed left-0 top-0 flex w-full justify-center border-b border-gray-300 bg-gradient-to-b from-zinc-200 pb-6 pt-8 backdrop-blur-2xl dark:border-neutral-800 dark:bg-zinc-800/30 dark:from-inherit lg:static lg:w-auto  lg:rounded-xl lg:border lg:bg-gray-200 lg:p-4 lg:dark:bg-zinc-800/30">
          Made with ❤️ in the EthGlobal&nbsp;
          <code className="font-mono font-bold">LFGHO</code>&nbsp;hackathon
        </p>
        <div className="fixed bottom-0 left-0 flex h-48 w-full items-end justify-center bg-gradient-to-t from-white via-white dark:from-black dark:via-black lg:static lg:h-auto lg:w-auto lg:bg-none">
          <a
            className="pointer-events-none flex place-items-center gap-2 p-8 lg:pointer-events-auto lg:p-0"
            href="https://github.com/jvaleskadevs/flamingho"
            target="_blank"
            rel="noopener noreferrer"
          >
            By{" "}
            <Image
              src="/vercel.svg"
              alt="Vercel Logo"
              className="dark:invert"
              width={100}
              height={24}
              priority
            />
          </a>
        </div>
      </div>

      <div>
      { isConnected && (
      <>
        <p className="text-sm font-semibold w-full mx-auto">Sepolia:</p>
        <p className="text-sm font-semibold w-full mx-auto">usdc: {balanceUSDCSepolia?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">gho: {balanceGHO?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">capacity: {(bucketGHO as any)?.[0]?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">level: {(bucketGHO as any)?.[1]?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto mt-2">Optimism Goerli:</p>
        <p className="text-sm font-semibold w-full mx-auto">usdc: {balanceUSDCOpt?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">fgho: {balanceFlaminGHO?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">capacity: {(bucketFlaminGHO as any)?.[0]?.toString()}</p>
        <p className="text-sm font-semibold w-full mx-auto">level: {(bucketFlaminGHO as any)?.[1]?.toString()}</p>
        </>)}
               
        <>
          <input
            type="number"
            value={amount}
            placeholder="Amount"
            onChange={(e) => setAmount(parseInt(e.target.value))}
            className="rounded-xl px-6 py-4 text-xl text-pink-500 font-bold w-full mt-8"
            //disabled={isConnected !== true}
          />
        </>

        <div className="flex flex-row justify-between gap-2">
          <div className="flex-col py-2 gap-1 justify-center">
            <button
              className={`${buttonStyle} bg-green-500`}
              onClick={() => onBuyGHOClick()}
              disabled={chain?.id !== sepolia.id}
            >
              { ((isLoadingGhoApprove || isLoadingUsdcSepoliaApprove) && currentAction === 'buy')
                  ? 'Approving..' : isLoadingGhoBuy 
                    ? 'Loading..' : 'Buy GHO' }
            </button>
            <p>*Sepolia</p>
          </div>
          <div className="flex-col py-2 gap-1 justify-center">
            <button 
              className={`${buttonStyle} bg-red-500`} 
              onClick={() => onSellGHOClick()}
              disabled={chain?.id !== sepolia.id}
            >
              { ((isLoadingGhoApprove || isLoadingUsdcSepoliaApprove) && currentAction === 'sell')
                  ? 'Approving..' : isLoadingGhoSell 
                    ? 'Loading..' : 'Sell GHO' }
            </button>
            <p className="w-full">*Sepolia</p>
          </div>
          <div className="flex-col py-2 gap-1 justify-center">
            <button 
              className={`${buttonStyle} bg-green-500`}
              onClick={() => onBuyFlaminGHOClick()}
              disabled={chain?.id !== optimismGoerli.id}
            >
              { ((isLoadingFlaminGhoApprove || isLoadingUsdcOptApprove) && currentAction === 'buy')
                  ? 'Approving..' : isLoadingFlaminGhoBuy 
                    ? 'Loading..' : 'Buy fGHO' }
            </button>
            <p>*Optimism Goerli</p>
          </div>
          <div className="flex-col py-2 gap-1 justify-center">
            <button 
              className={`${buttonStyle} bg-red-500`}
              onClick={() => onSellFlaminGHOClick()}
              disabled={chain?.id !== optimismGoerli.id}
            >
              { ((isLoadingFlaminGhoApprove || isLoadingUsdcOptApprove) && currentAction === 'sell')
                  ? 'Approving..' : isLoadingFlaminGhoSell 
                    ? 'Loading..' : 'Sell fGHO' }
            </button>
            <p>*Optimism Goerli</p>
          </div>
        </div>
        <p className="text-sm font-semibold max-w-sm w-full mx-auto">{message}</p>
        <p className="text-sm font-semibold max-w-sm w-full mx-auto">{errorMessage}</p>
      </div>      
      
      <div className="flex flex-col justify-between items-center gap-8">
        <div className={`${birthstone.className}`}>
          <h2 className="text-9xl tracking-wide text-pink-300 font-bold px-8"><i>FlaminGHO</i></h2>
          <h3 className="text-7xl tracking-widest text-pink-500 font-bold px-10 py-4"><i>let's flaminGHO</i></h3>
        </div>
        <ConnectKitButton />
      </div>
    </main>
  );
}
