const makeCommand = (bin, spec) => {
    return `${bin} '${spec.format.join("")}' ${spec.args.join(" ")}`;
};

export default makeCommand;
