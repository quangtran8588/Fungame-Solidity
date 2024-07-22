import axios from "axios";

export interface Ticker {
  symbol: string;
  price: string;
}

export interface Response {
  ticker: Ticker | undefined;
  error: Error | undefined;
}

const API_URL = process.env.PRICE_TICKER_API as string;

export const fetchTickerPrice = async (symbol: string): Promise<Response> => {
  try {
    const response: Ticker = (
      await axios.get(API_URL, { params: { symbol: symbol } })
    ).data;
    return { ticker: response, error: undefined };
  } catch (error: any) {
    return { ticker: undefined, error: error };
  }
};
