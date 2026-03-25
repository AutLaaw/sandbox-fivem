import React, { Fragment, useEffect, useState } from 'react';
import { makeStyles } from '@mui/styles';
import { Slide } from '@mui/material';

const useStyles = makeStyles((theme) => ({
	container: {
		position: 'absolute',
		bottom: 15,
		left: 0,
		right: 0,
		margin: 'auto',
		height: 44,
		width: 'fit-content',
		pointerEvents: 'none',
		display: 'flex',
		alignItems: 'center',
		zIndex: 1,
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}92 100%)`,
		borderRadius: 8,
		border: `1px solid ${theme.palette.info.main}35`,
		boxShadow: '0 4px 16px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		padding: '0 14px',
		gap: 10,
		'& small': {
			fontSize: 10.5,
			fontWeight: 700,
			textTransform: 'uppercase',
			letterSpacing: '1.2px',
			color: theme.palette.info.main,
			padding: '4px 8px',
			background: 'rgba(0, 0, 0, 0.35)',
			borderRadius: 4,
			border: `1px solid ${theme.palette.info.main}20`,
		},
	},
	label: {
		color: theme.palette.text.main,
		fontSize: 13.5,
		textShadow: '0 2px 6px rgba(0, 0, 0, 0.6)',
		display: 'flex',
		alignItems: 'center',
		gap: 10,
		fontWeight: 500,

		'& .highlight': {
			color: theme.palette.primary.main,
			fontWeight: 700,
			padding: '3px 9px',
			background: 'rgba(0, 0, 0, 0.35)',
			border: `1px solid ${theme.palette.primary.main}30`,
			borderRadius: 4,
			fontSize: 12,
			textTransform: 'uppercase',
			letterSpacing: '0.6px',
			display: 'inline-flex',
			alignItems: 'center',
			gap: 4,
			textShadow: '0 2px 4px rgba(0, 0, 0, 0.7)',
		},
		'& .separator': {
			color: theme.palette.border.divider,
			margin: '0 2px',
			opacity: 0.5,
		},
	},
}));

export default ({ message }) => {
	const classes = useStyles();
	return (
		<Slide direction="up" in={true}>
			<div className={classes.container}>
				<small>Help</small>
				<div className={classes.label}>
					<span className="highlight">Double Click</span>
					<span>Play Character</span>
					<span className="separator">•</span>
					<span className="highlight">Right Click</span>
					<span>Delete</span>
				</div>
			</div>
		</Slide>
	);
};
