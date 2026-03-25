import React from 'react';
import { useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';

import { Motd } from '../../components';
import logo from '../../assets/imgs/logo_banner.png';

import CharacterButton from './components/CharacterButton';
import Help from './components/Help';
import CreateCharacter from './components/CreateCharacter';

const useStyles = makeStyles((theme) => ({
	canvas: {
		height: '100vh',
		width: '100vw',
		position: 'relative',
	},
	logo: {
		width: 300,
		height: 169,
		position: 'absolute',
		right: 24,
		top: 24,
		filter: 'drop-shadow(0 4px 12px rgba(0, 0, 0, 0.5))',
		transition: 'transform 0.3s ease',
		'&:hover': {
			transform: 'scale(1.02)',
		},
	},
	charContainer: {
		position: 'absolute',
		bottom: 110,
		left: 0,
		right: 0,
		margin: 'auto',
		width: 'fit-content',
		height: 'fit-content',
		display: 'flex',
		gap: 10,
		maxWidth: '96vw',
		maxHeight: 110,
		overflow: 'auto',
		padding: '4px 6px',
		background: 'rgba(0, 0, 0, 0.25)',
		borderRadius: 10,
		boxShadow: '0 6px 24px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		'&::-webkit-scrollbar': {
			height: 6,
			width: 6,
		},
		'&::-webkit-scrollbar-thumb': {
			background: `${theme.palette.primary.main}70`,
			borderRadius: 3,
			transition: 'background 0.2s ease',
		},
		'&::-webkit-scrollbar-thumb:hover': {
			background: `${theme.palette.primary.main}`,
		},
		'&::-webkit-scrollbar-track': {
			background: 'rgba(0, 0, 0, 0.3)',
			borderRadius: 3,
		},
	},
}));

export default (props) => {
	const classes = useStyles();

	const characters = useSelector((state) => state.characters.characters);
	const characterLimit = useSelector(
		(state) => state.characters.characterLimit,
	);
	const motd = useSelector((state) => state.characters.motd);

	return (
		<div className={classes.canvas}>
			{Boolean(motd) && <Motd message={motd} />}
			<Help />
			<img className={classes.logo} src={logo} />
			<div className={classes.charContainer}>
				{characters.length < characterLimit && <CreateCharacter />}
				{characters.length > 0 &&
					characters.map((char, i) => {
						return (
							<CharacterButton key={i} id={i} character={char} />
						);
					})}
			</div>
		</div>
	);
};
