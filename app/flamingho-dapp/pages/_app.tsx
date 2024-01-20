import { WagmiConfig, createConfig } from "wagmi";
import { sepolia, optimismGoerli } from "wagmi/chains";
import { ConnectKitProvider, ConnectKitButton, getDefaultConfig } from "connectkit";
import "@/styles/globals.css";
import type { AppProps } from "next/app";

const chains = [sepolia, optimismGoerli];

const config = createConfig(
  getDefaultConfig({
    // Required API Keys
    alchemyId: process.env.NEXT_PUBLIC_ALCHEMY_ID ?? '', // or infuraId
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ?? '',

    // Required
    appName: "flamingho",
    
    // chains,
    chains,

    // Optional
    appDescription: "flamingho",
    appUrl: "https://family.co", // your app's url
    appIcon: "https://family.co/logo.png", // your app's icon, no bigger than 1024x1024px (max. 1MB)
  }),
);

export default function App({ Component, pageProps }: AppProps) {
  return (
    <WagmiConfig config={config}>
      <ConnectKitProvider>
        <Component {...pageProps} />
      </ConnectKitProvider>
    </WagmiConfig>  
  );
}
