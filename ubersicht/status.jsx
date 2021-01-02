import * as config from "./config.json";
import makeCommand from "./lib/util.jsx";
import makeTextStyle from "./lib/style.jsx";

export const className = {
    bottom: 0,
    right: 0,
};

export const refreshFrequency = 5000;
export const command = makeCommand(config.binary, config.info);
export const render = ({output}) => {
    return (
        <div style={makeTextStyle(config)}>
            {output}
        </div>
    );
};

export default null;
