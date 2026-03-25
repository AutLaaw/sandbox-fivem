/* eslint-disable react/prop-types */
import React from 'react';
import { Fade } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { useDispatch } from 'react-redux';

import { STATE_CREATE } from '../../../util/States';

const useStyles = makeStyles((theme) => ({
	container: {
		width: 100,
		height: 100,
		display: 'inline-flex',
		flexDirection: 'column',
		alignItems: 'center',
		justifyContent: 'center',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}90 100%)`,
		borderRadius: 8,
		border: `1.5px dashed ${theme.palette.success.main}50`,
		textAlign: 'center',
		transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
		boxShadow: '0 3px 10px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		position: 'relative',
		overflow: 'hidden',
		'&::before': {
			content: '""',
			position: 'absolute',
			inset: 0,
			background: `radial-gradient(circle at center, ${theme.palette.success.main}20 0%, transparent 70%)`,
			opacity: 0,
			transition: 'opacity 0.3s ease',
		},
		'&:hover': {
			transform: 'translateY(-2px)',
			borderColor: theme.palette.success.main,
			borderStyle: 'solid',
			boxShadow: `0 6px 20px rgba(0, 0, 0, 0.5), 0 0 16px ${theme.palette.success.main}25, inset 0 1px 0 rgba(255, 255, 255, 0.08)`,
			cursor: 'pointer',
			'&::before': {
				opacity: 1,
			},
			'& $icon': {
				transform: 'rotate(90deg) scale(1.15)',
			},
		},
	},
	icon: {
		fontSize: 32,
		color: theme.palette.success.main,
		transition: 'transform 0.3s ease',
		filter: 'drop-shadow(0 2px 8px rgba(0, 0, 0, 0.5))',
	},
	label: {
		fontSize: 12,
		marginTop: 8,
		color: theme.palette.success.main,
		fontWeight: 600,
		textTransform: 'uppercase',
		letterSpacing: '0.5px',
		textShadow: '0 2px 4px rgba(0, 0, 0, 0.5)',
	},
}));

export default () => {
	const classes = useStyles();
	const dispatch = useDispatch();

	const onClick = () => {
		dispatch({
			type: 'SET_STATE',
			payload: { state: STATE_CREATE },
		});
	};

	return (
		<Fade in={true}>
			<div className={classes.container} onClick={onClick}>
				<FontAwesomeIcon icon="plus-circle" className={classes.icon} />
				<div className={classes.label}>Create</div>
			</div>
		</Fade>
	);
};
