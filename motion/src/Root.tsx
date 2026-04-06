import "./index.css";
import { Composition } from "remotion";
import { QuotesyPromo } from "./QuotesyPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="QuotesyPromo"
        component={QuotesyPromo}
        durationInFrames={645}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
