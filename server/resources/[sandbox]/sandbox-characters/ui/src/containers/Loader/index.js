import React from 'react';
import { useSelector } from 'react-redux';
import { Fade, LinearProgress } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { styled } from '@mui/material/styles';
import { linearProgressClasses } from '@mui/material/LinearProgress';

import logo from '../../assets/imgs/logo_banner.png';

const useStyles = makeStyles((theme) => ({
	container: {
		height: 'fit-content',
		width: 600,
		position: 'absolute',
		bottom: 0,
		top: 0,
		left: 0,
		right: 0,
		margin: 'auto',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}95 100%)`,
		borderRadius: 12,
		border: `1px solid ${theme.palette.primary.main}40`,
		boxShadow: `0 12px 48px rgba(0, 0, 0, 0.7), 0 0 0 1px ${theme.palette.primary.main}20`,
		overflow: 'hidden',
	},
	details: {
		width: '100%',
		padding: '32px 40px',
		textAlign: 'center',
	},
	label: {
		color: theme.palette.text.main,
		fontSize: 22,
		fontWeight: 600,
		textShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
		textAlign: 'center',
		marginTop: 24,
	},
	img: {
		maxWidth: 350,
		width: '100%',
		filter: 'drop-shadow(0 4px 12px rgba(0, 0, 0, 0.5))',
	},
	progressContainer: {
		padding: '0 40px 32px',
	},
}));

export default () => {
	const classes = useStyles();

	const loading = useSelector((state) => state.loader.loading);
	const message = useSelector((state) => state.loader.message);

	const BorderLinearProgress = styled(LinearProgress)(({ theme }) => ({
		height: 6,
		borderRadius: 3,
		[`&.${linearProgressClasses.colorPrimary}`]: {
			backgroundColor: 'rgba(0, 0, 0, 0.3)',
		},
		[`& .${linearProgressClasses.bar}`]: {
			backgroundColor: theme.palette.primary.main,
			borderRadius: 3,
			boxShadow: `0 0 10px ${theme.palette.primary.main}40`,
		},
	}));

	if (!loading) return null;
	return (
		<Fade in={true} duration={1000}>
			<div className={classes.container}>
				<div className={classes.details}>
					<img className={classes.img} src={logo} alt="Logo" />
					<div className={classes.label}>{message}</div>
				</div>
				<div className={classes.progressContainer}>
					<BorderLinearProgress
						classes={{
							bar: classes.progressbar,
							bar1: classes.progressbar,
						}}
					/>
				</div>
			</div>
		</Fade>
	);
};
