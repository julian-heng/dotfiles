import * as config from "./config.json"

const style = {
    background: config.style.color.backgroundPrimary,
    height: 20,
    width: "100%",
    bottom: 0,
    right: 0,
    left: 0,
    zIndex: -1,
    position: "fixed",
    overflow: "hidden",

    borderTopStyle: "solid",
    borderTopColor: config.style.color.backgroundSecondary,
    borderTopWidth: 1,
};

export const refreshFrequency = false;
export const render = ({output}) => <div style={style} />;

export default null;
