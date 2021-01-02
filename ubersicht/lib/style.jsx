const makeTextStyle = (config) => {
    return {
        marginTop: 0,
        marginLeft: 5,
        marginBottom: 4,
        marginRight: 5,

        color: config.style.color.foreground,
        font: `${config.style.font.size}px ${config.style.font.style}`,
    };
};

export default makeTextStyle;
