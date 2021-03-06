SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestionnaire de Stock de Masse
--			    Traitement Evènement Fin Mission
-- @v_mission : Mission
-- @v_demande : Demande
-- @v_cause   : Cause de fin mission
-- @v_agv     : AGV
-- @v_charge  : Bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_EVT_ORDRE_MOUVEMENT]
	@v_message			int,
	@v_type				int,
	@v_emetteur_interne int,
	@v_emetteur_externe int,
	@v_agv				tinyint,
	@v_ordre			int,
	@v_action			int,
	@v_idsysteme		bigint,
	@v_idbase			bigint,
	@v_idsousbase		bigint
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int

declare @retour				int,
		@trace				varchar(7500)
DECLARE @adresse			VARCHAR(20)
DECLARE @Laize				INT
DECLARE @idSystemeDepose	BIGINT
DECLARE @idBaseDepose		BIGINT
DECLARE @idsousbasedepose	BIGINT
DECLARE @HauteurInitiale	INT
DECLARE @HauteurCourante	INT
DECLARE @NbBobinesMax		INT

set @CODE_OK = 0
set @CODE_KO = 1

set @retour = @CODE_OK
DECLARE @procStock VARCHAR(128) = 'SPC_DDG_EVT_ORDRE_MOUVEMENT' -- OBJECT_NAME(@@PROCID)

	select @adresse = ADR_ADRESSE from INT_ADRESSE
	where INT_ADRESSE.ADR_IDSYSTEME = @v_idsysteme
	and INT_ADRESSE.ADR_IDBASE = @v_idbase
	and INT_ADRESSE.ADR_IDSOUSBASE = @v_idsousbase

	-- Données d'entrée
	set @trace = 'EXEC ' + @procStock +' @v_message='+CONVERT(varchar,isnull(@v_message,0))
				+',@v_type='+CONVERT(varchar,isnull(@v_type,0))
				+',@v_emetteur_interne='+CONVERT(varchar,isnull(@v_emetteur_interne,0))
				+',@v_emetteur_externe='+CONVERT(varchar,isnull(@v_emetteur_externe,0))
				+',@v_agv='+CONVERT(varchar,isnull(@v_agv,0))
				+',@v_ordre='+CONVERT(varchar,isnull(@v_ordre,0))
				+',@v_action='+CONVERT(varchar,isnull(@v_action,0))
				+',@v_idsysteme='+CONVERT(varchar,isnull(@v_idsysteme,0))
				+',@v_idbase='+CONVERT(varchar,isnull(@v_idbase,0))
				+',@v_idsousbase='+CONVERT(varchar,isnull(@v_idsousbase,0))
				+',@adresse='+CONVERT(varchar,isnull(@adresse,0))

		exec INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @trace

	-- En direction d'une base d'attente ou DEC
	IF @v_action = 1
	BEGIN
		-- En direction d'un DEC du stock de masse?
		IF EXISTS (SELECT 1	FROM INT_ADRESSE
			WHERE INT_ADRESSE.ADR_IDSYSTEME = @v_idsysteme
			AND INT_ADRESSE.ADR_IDBASE = @v_idbase
			AND INT_ADRESSE.ADR_IDSOUSBASE = @v_idsousbase
			AND INT_ADRESSE.ADR_IDTYPEMAGASIN = 5
			AND INT_ADRESSE.ADR_MAGASIN = 2
			AND ADR_COTE IN (1, 2))
		BEGIN
			set @trace = 'Entrée dans la modification de l''allée'
			+',@v_action='+CONVERT(varchar,isnull(@v_action,0))
			+',@adresse='+CONVERT(varchar,isnull(@adresse,0))
			exec INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @trace

			--S'il n'y a pas de charge dans l'allée
			IF NOT EXISTS (SELECT 1 FROM INT_ADRESSE as DEC_DEP
				inner join INT_ADRESSE as ADR_DEP on ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
													and ADR_DEP.ADR_ALLEE = DEC_DEP.ADR_ALLEE
													and ADR_DEP.ADR_COULOIR = DEC_DEP.ADR_COULOIR
													and ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
													and ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
				inner join INT_CHARGE_VIVANTE on INT_CHARGE_VIVANTE.CHG_IDSYSTEME = ADR_DEP.ADR_IDSYSTEME
												and INT_CHARGE_VIVANTE.CHG_IDBASE = ADR_DEP.ADR_IDBASE
												and INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = ADR_DEP.ADR_IDSOUSBASE
				WHERE DEC_DEP.ADR_IDSYSTEME = @v_idsysteme
						AND DEC_DEP.ADR_IDBASE = @v_idbase
						AND DEC_DEP.ADR_IDSOUSBASE = @v_idsousbase
						and ADR_DEP.ADR_IDTYPEMAGASIN = 3)
			BEGIN
				-- On récupère les infos de charge sur l'AGV
				SELECT @Laize = SPC_CHARGE_BOBINE.SCB_LAIZE from INT_ADRESSE_AGV 
				inner join SPC_CHARGE_BOBINE on INT_ADRESSE_AGV.CHG_IDCHARGE = SPC_CHARGE_BOBINE.SCB_IDCHARGE
					where INT_ADRESSE_AGV.IAG_IDAGV = @v_agv

				-- Récupération des infos d'allée de dépose
				SELECT @idSystemeDepose = ADR_DEP.ADR_IDSYSTEME
						, @idBaseDepose = ADR_DEP.ADR_IDBASE 
						, @idsousbasedepose = ADR_DEP.ADR_IDSOUSBASE FROM INT_ADRESSE as DEC_DEP
					inner join INT_ADRESSE as ADR_DEP  on ADR_DEP.ADR_MAGASIN = DEC_DEP.ADR_MAGASIN
														and ADR_DEP.ADR_ALLEE = DEC_DEP.ADR_ALLEE
														and ADR_DEP.ADR_COULOIR = DEC_DEP.ADR_COULOIR
														and ADR_DEP.ADR_COTE = DEC_DEP.ADR_COTE
														and ADR_DEP.ADR_RACK = DEC_DEP.ADR_RACK
					WHERE DEC_DEP.ADR_IDSYSTEME = @v_idsysteme
							AND DEC_DEP.ADR_IDBASE = @v_idbase
							AND DEC_DEP.ADR_IDSOUSBASE = @v_idsousbase
							and ADR_DEP.ADR_IDTYPEMAGASIN = 3

				SELECT @HauteurInitiale = STRUCTURE.STR_HAUTEUR_INITIALE from STRUCTURE
					where STRUCTURE.STR_SYSTEME = @idSystemeDepose 
						and STRUCTURE.STR_BASE = @idBaseDepose 
						and STRUCTURE.STR_SOUSBASE = @idsousbasedepose

				-- Si la base est contraintes par rapport à ce type de laize
				IF EXISTS (select 1 from SPC_STK_NBLAIZEHAUTEUR
				inner join SPC_CHG_TYPE_LAIZE on SPC_CHG_TYPE_LAIZE.SLT_ID = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
				inner join SPC_CHG_LAIZE on SPC_CHG_LAIZE.SCL_TYPE_LAIZE = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
				where SPC_CHG_LAIZE.SCL_LAIZE = @Laize
					AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME = @idSystemeDepose
					AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE = @idBaseDepose
					AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE = @idsousbasedepose)
				BEGIN
					--On calcul la hauteur max contrainte et on la compare avec la hauteur max de la base
					--Nombre de bobines max
					select @NbBobinesMax = SPC_STK_NBLAIZEHAUTEUR.NLH_NBBOBINES from SPC_STK_NBLAIZEHAUTEUR
						inner join SPC_CHG_TYPE_LAIZE on SPC_CHG_TYPE_LAIZE.SLT_ID = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
						inner join SPC_CHG_LAIZE on SPC_CHG_LAIZE.SCL_TYPE_LAIZE = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
						where SPC_CHG_LAIZE.SCL_LAIZE = @Laize
				
					--Calcul de la hauteur correspondante par rapport à la laize
					SET @HauteurCourante = @NbBobinesMax * @Laize
				
					--On prend le minimum des 2
					IF @HauteurCourante > @HauteurInitiale
						SET @HauteurCourante = @HauteurInitiale
				
					--Changement de la hauteur courante dans la table structure
					UPDATE STRUCTURE set STR_HAUTEUR_COURANTE = @HauteurCourante where STRUCTURE.STR_SYSTEME = @idSystemeDepose
											AND STRUCTURE.STR_BASE = @idBaseDepose
											and STRUCTURE.STR_SOUSBASE = @idSousBaseDepose
				
				END
				ELSE -- Pas de contraintes, la hauteur courante = hauteur initiale
				BEGIN
					UPDATE STRUCTURE set STR_HAUTEUR_COURANTE = @HauteurInitiale where STRUCTURE.STR_SYSTEME = @idSystemeDepose
											AND STRUCTURE.STR_BASE = @idBaseDepose
											and STRUCTURE.STR_SOUSBASE = @idSousBaseDepose
				END				
				set @trace = 'Sortie de la modification de l''allée'
				+',@adresse='+CONVERT(varchar,isnull(@adresse,0))
				+',@Laize='+CONVERT(varchar,isnull(@Laize,0))
				+',@HauteurInitiale='+CONVERT(varchar,isnull(@HauteurInitiale,0))
				+',@HauteurCourante='+CONVERT(varchar,isnull(@HauteurCourante,0))
				+',@NbBobinesMax='+CONVERT(varchar,isnull(@NbBobinesMax,0))
				exec INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @trace
			END
		END
	END
END
