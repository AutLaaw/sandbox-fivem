/* eslint-disable react/prop-types */
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Fade } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { SelectSpawn } from '../../../util/NuiEvents';
import Nui from '../../../util/Nui';

const useStyles = makeStyles((theme) => ({
	container: {
		width: '100%',
		height: 60,
		padding: 0,
		display: 'flex',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}92 100%)`,
		borderRadius: 8,
		border: `1px solid ${theme.palette.secondary.light}30`,
		transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
		userSelect: "none",
		boxShadow: '0 3px 10px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		overflow: 'hidden',
		position: 'relative',
		'&:not(:last-of-type)': {
			marginBottom: 8,
		},
		'&::before': {
			content: '""',
			position: 'absolute',
			left: 0,
			top: 0,
			bottom: 0,
			width: 3,
			background: `linear-gradient(180deg, ${theme.palette.secondary.light}60 0%, ${theme.palette.secondary.light}20 100%)`,
			transition: 'all 0.3s ease',
		},
		'&.active': {
			borderColor: `${theme.palette.primary.main}60`,
			boxShadow: `0 4px 16px ${theme.palette.primary.main}40, 0 0 0 1px ${theme.palette.primary.main}30, inset 0 1px 0 rgba(255, 255, 255, 0.08)`,
			'&::before': {
				background: `linear-gradient(180deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.main}80 100%)`,
				boxShadow: `0 0 10px ${theme.palette.primary.main}60`,
			},
		},
		'&:hover': {
			transform: 'translateY(-2px)',
			borderColor: `${theme.palette.primary.dark}50`,
			boxShadow: '0 6px 20px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.08)',
			cursor: 'pointer',
			'&::before': {
				background: `linear-gradient(180deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.dark}70 100%)`,
				width: 4,
			},
			'& $spawnIcon::after': {
				opacity: 1,
			},
			'& $arrow': {
				opacity: 0.7,
				transform: 'translateX(0)',
			},
		},
	},
	spawnIcon: {
		width: 56,
		display: 'flex',
		alignItems: 'center',
		justifyContent: 'center',
		fontSize: 18,
		background: 'rgba(0, 0, 0, 0.25)',
		borderRight: `1px solid ${theme.palette.border.divider}40`,
		color: theme.palette.primary.main,
		textShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
		position: 'relative',
		'&::after': {
			content: '""',
			position: 'absolute',
			right: 0,
			top: '50%',
			transform: 'translateY(-50%)',
			width: 2,
			height: 30,
			background: `linear-gradient(180deg, transparent, ${theme.palette.primary.main}40, transparent)`,
			opacity: 0,
			transition: 'opacity 0.3s ease',
		},
	},
	details: {
		padding: '0 14px',
		flex: 1,
		display: 'flex',
		alignItems: 'center',
		justifyContent: 'space-between',
	},
	detail: {
		fontSize: 15,
		fontWeight: 600,
		color: theme.palette.text.main,
		textShadow: '0 2px 6px rgba(0, 0, 0, 0.5)',
		letterSpacing: '0.5px',
	},
	arrow: {
		fontSize: 14,
		color: theme.palette.text.alt,
		opacity: 0,
		transition: 'all 0.3s ease',
		transform: 'translateX(-5px)',
	},
}));

export default ({ spawn, onPlay }) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const selected = useSelector((state) => state.spawn.selected);

	const onClick = () => {
		Nui.send(SelectSpawn, { spawn });
		dispatch({
			type: 'SELECT_SPAWN',
			payload: spawn,
		});
	};

	return (
		<Fade in={true}>
			<div
				className={`${classes.container} ${
					selected?.id == spawn?.id ? 'active' : ''
				}`}
				onDoubleClick={onPlay}
				onClick={onClick}
			>
				<div className={classes.spawnIcon}>
					<FontAwesomeIcon
						icon={Boolean(spawn.icon) ? spawn.icon : 'location-dot'}
					/>
				</div>
				<div className={classes.details}>
					<div className={classes.detail}>{spawn.label}</div>
					<FontAwesomeIcon
						icon="chevron-right"
						className={classes.arrow}
					/>
				</div>
			</div>
		</Fade>
	);
};
