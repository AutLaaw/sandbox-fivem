import React, { useEffect, useState } from 'react';
import { useDispatch } from 'react-redux';
import { Fade } from '@mui/material';
import { makeStyles } from '@mui/styles';

import Nui from '../../util/Nui';
import { GetData } from '../../util/NuiEvents';

import logo from '../../assets/imgs/logo_banner.png';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		height: 'fit-content',
		width: '55%',
		position: 'absolute',
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
		margin: 'auto',
		textAlign: 'center',
		fontSize: 30,
		color: theme.palette.text.main,
		zIndex: 1000,
		padding: 36,
	},
	img: {
		maxWidth: 750,
		width: '100%',
	},
	innerBody: {
		lineHeight: '250%',
		transform: 'translate(0%, 50%)',
	},
	splashHeader: {
		fontSize: '2vw',
		display: 'block',
	},
	splashBranding: {
		color: theme.palette.primary.main,
	},
	splashTip: {
		fontSize: '1vw',
		animation: '$blinker 1s linear infinite',
	},
	splashTipHighlight: {
		fontWeight: 500,
		color: theme.palette.primary.main,
		opacity: 1,
	},
	vertical: { verticalAlign: 'middle' },
	'@keyframes blinker': {
		'50%': {
			opacity: 0.3,
		},
	},
}));

export default (props) => {
	const dispatch = useDispatch();
	const classes = useStyles();

	const [show, setShow] = useState(true);

	const onAnimEnd = () => {
		Nui.send(GetData);
		dispatch({
			type: 'LOADING_SHOW',
			payload: { message: 'Loading Server Data' },
		});
	};

	const Bleh = (e) => {
		if (e.which == 1 || e.which == 13 || e.which == 32) {
			setShow(false);
		}
	};

	useEffect(() => {
		['click', 'keydown', 'keyup'].forEach(function (e) {
			window.addEventListener(e, Bleh);
		});

		return () => {
			['click', 'keydown', 'keyup'].forEach(function (e) {
				window.removeEventListener(e, Bleh);
			});
		};
	}, []);

	return (
		<Fade in={show} onExited={onAnimEnd}>
			<div className={classes.wrapper}>
			<img className={classes.img} src={logo} />
			<div className={classes.innerBody}>
				<span className={classes.splashHeader}>
					Welcome To <span className={classes.splashBranding}>SandboxRP</span>
				</span>
				<span
					className={classes.splashTip}
				>
					Press {' '}
					<img
						className={classes.vertical}
						width={30}
						src={'data:image/svg+xml,%3csvg id=\'Layer_2\' data-name=\'Layer 2\' xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 330.44 330.44\'%3e %3cdefs%3e %3cstyle%3e .cls-1 %7b fill: %23fff; %7d %3c/style%3e %3c/defs%3e %3cg id=\'Layer_1-2\' data-name=\'Layer 1\'%3e %3cg%3e %3cpath class=\'cls-1\' d=\'m164.48,330.44c-41.34,0-82.69,0-124.03,0-3.53,0-7.1.07-10.56-.64-11.7-2.4-20.55-8.72-26-19.52C.8,304.15,0,297.57,0,290.82c.01-26.22.01-52.44.01-78.66,0-15.12-.02-30.25,0-45.37,0-8.6,2.31-16.51,7.63-23.34,7.29-9.35,17.05-14.04,28.81-14.09,30.33-.13,60.66-.04,91-.04q1.86,0,1.86-1.92c0-30.37-.05-60.75.02-91.12.04-17.2,11.76-30.8,26.33-34.72C159.89.41,164.15.01,168.47,0c28.21-.01,56.42.01,84.64.02,12.55,0,25.1-.02,37.64-.03,5.42,0,10.79.42,15.93,2.34,6.87,2.57,12.51,6.77,16.81,12.75,5.11,7.09,6.96,15.08,6.93,23.7-.06,17.7,0,35.4,0,53.1,0,35.61,0,71.22.01,106.83,0,31.58.03,63.16,0,94.74-.01,15.42-8.79,28.64-22.6,34.24-4.39,1.78-8.99,2.71-13.72,2.71-43.21.03-86.43.02-129.64.02v.02Zm151.32-165.72h.04c0-43.5,0-87,0-130.5,0-.75,0-1.5-.12-2.24-1.58-9.48-11.61-17.58-20.44-17.49-19.57.19-39.14.05-58.7.05-23.47,0-46.95.02-70.42-.02-3.19,0-6.27.26-9.22,1.62-7.91,3.63-12.56,9.58-13.18,18.39-.33,4.77-.06,9.55-.06,14.33-.01,23.51,0,47.03,0,70.54,0,3.82.11,7.65-.13,11.46-.42,6.73-7.17,12.87-13.93,12.87-13.75,0-27.5-.07-41.26-.03-17.99.05-35.98-.16-53.97.12-3.01.05-5.81.9-8.46,2.25-5.12,2.62-8.17,7.02-10.34,12.16-.6,1.42-.95,2.9-1.07,4.45-.19,2.33.08,4.65.07,6.97-.03,24.51-.04,49.02-.05,73.54,0,17.2.14,34.4-.05,51.6-.09,8.09,5.2,15.94,12.31,19.26,3.7,1.73,7.56,1.9,11.54,1.89,27.05-.05,54.09-.02,81.14-.02,29.91,0,59.83,0,89.74,0,28.29.01,56.58.02,84.88.11,4.52.01,8.64-1.06,12.33-3.57,5.43-3.69,8.7-8.79,9.49-15.37.25-2.11-.14-4.23-.14-6.35.01-42,.01-84.01.01-126.01Z\'/%3e %3cpath class=\'cls-1\' d=\'m82.25,237.02c.16.77.63,1.08,1.01,1.45,9.53,9.51,19.06,19.01,28.58,28.52,1.21,1.21,2.34,2.47,2.81,4.19.73,2.69-.31,6.05-2.3,7.4-2.77,1.89-6.11,1.9-8.6.05-1.27-.95-2.36-2.09-3.48-3.21-13.02-13.01-26.03-26.02-39.04-39.04-.5-.5-1-1-1.46-1.53-3.09-3.52-3.02-7.03.29-10.38,4.11-4.17,8.27-8.29,12.42-12.43,9.86-9.82,19.72-19.64,29.58-29.46.95-.94,1.94-1.85,3.18-2.35,2.95-1.2,6.24-.23,8.21,2.36,1.9,2.49,1.88,5.87-.06,8.41-.38.49-.79.97-1.23,1.4-7.5,7.48-14.99,14.97-22.51,22.42-2.36,2.34-4.47,4.92-7.12,6.95-.55.42-.5.73.2.85.37.06.74.1,1.11.1,20.98,0,41.96-.02,62.94-.04,12.05-.01,24.1-.07,36.15-.03,3.62.01,7.24.18,10.8-.61,11.62-2.56,20.22-9.02,25.46-19.81,2.75-5.66,3.6-11.63,3.55-17.87-.12-15.33-.04-30.66-.04-45.99,0-10.76-.05-21.52,0-32.28.01-2.4-.24-4.82.32-7.2.74-3.1,3.79-5.51,6.9-5.47,2.92.04,6.14,2.63,6.81,5.5.19.81.28,1.63.28,2.47,0,28.63.02,57.25-.03,85.88,0,5.77-1.16,11.36-3.18,16.79-1.13,3.05-2.46,5.99-4.11,8.77-2.89,4.88-6.76,8.93-11.05,12.57-5.63,4.77-12.09,7.95-19.2,9.87-4.93,1.33-9.94,1.77-15.03,1.76-33.57-.03-67.14-.02-100.71-.02-.45,0-.9,0-1.46,0Z\'/%3e %3c/g%3e %3c/g%3e %3c/svg%3e'}
					/>
					{' '}
					or {' '}
					<img
						className={classes.vertical}
						width={60}
						src={'data:image/svg+xml,%3csvg id=\'Layer_2\' data-name=\'Layer 2\' xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 701 330\'%3e %3cdefs%3e %3cstyle%3e .cls-1 %7b fill: %23fff; %7d .cls-2 %7b fill: none; stroke: %23fff; stroke-miterlimit: 10; stroke-width: 14px; %7d %3c/style%3e %3c/defs%3e %3cg id=\'Layer_1-2\' data-name=\'Layer 1\'%3e %3cg%3e %3cpath class=\'cls-1\' d=\'m661.99,14c13.79,0,25.01,11.22,25.01,25.01v251.97c0,13.79-11.22,25.01-25.01,25.01H39.01c-13.79,0-25.01-11.22-25.01-25.01V39.01c0-13.79,11.22-25.01,25.01-25.01h622.97m0-14H39.01C17.47,0,0,17.47,0,39.01v251.97c0,21.55,17.47,39.01,39.01,39.01h622.97c21.55,0,39.01-17.47,39.01-39.01V39.01c0-21.55-17.47-39.01-39.01-39.01h0Z\'/%3e %3cpath class=\'cls-2\' d=\'m631,138.01v58.97c0,21.55-17.47,39.01-39.01,39.01H120.01c-21.55,0-39.01-17.47-39.01-39.01v-58.97\'/%3e %3c/g%3e %3c/g%3e %3c/svg%3e'}
					/>
					{' '}
					to continue
				</span>
			</div>
		</div>
		</Fade>
	);
};
