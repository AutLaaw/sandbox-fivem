import React, { useEffect, useState } from 'react';
import { Grid } from '@material-ui/core';
import { makeStyles } from '@material-ui/styles';
import moment from 'moment';

import {
    ResponsiveContainer,
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip
} from 'recharts';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		padding: '20px 10px 20px 20px',
	},
}));

const data = [
    {
        name: "Page A",
        count: 10,
    },
    {
        name: "Page B",
        count: 10,
    },
    {
        name: "Page C",
        count: 32,
    },
    {
        name: "Page D",
        count: 64,
    },
    {
        name: "Page E",
        count: 128,
    },
    {
        name: "Page F",
        count: 10,
    },
    {
        name: "Page F",
        count: 10,
    },
    {
        name: "Page F",
        count: 10,
    },
    {
        name: "Page F",
        count: 20,
    },
];

export default ({ current, history }) => {
	const classes = useStyles();
    const [pHistory, setPHistory] = useState({});

    useEffect(() => {
        const now = moment().unix();
        let points = history.map(h => {
            return { ...h, name: moment.unix(h.time).format('HH:mm') };
        });

        points.push({
            time: now,
            count: current,
            name: 'Now',
        });

        setPHistory(points);
    }, [history, current]);

	return (
        <ResponsiveContainer width="100%" height="100%">
            <AreaChart
                width={500}
                height={400}
                data={pHistory}
                margin={{
                    top: 10,
                    right: 30,
                    left: 0,
                    bottom: 0
                }}
            >
                <XAxis dataKey="name" />
                <YAxis allowDecimals={false} />
                <Area type="monotone" dataKey="count" stroke="#E8A933" fill="#E5A502" />
            </AreaChart>
        </ResponsiveContainer>
	);
};