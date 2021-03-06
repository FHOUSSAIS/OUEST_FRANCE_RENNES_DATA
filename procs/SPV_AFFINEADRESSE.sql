SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_AFFINEADRESSE
-- Paramètre d'entrée	: @v_cyclique : Affinage cyclique ou non
--			  @v_iag_idagv : Identifiant AGV
--			  @v_ord_idordre : Identifiant ordre
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--				@CODE_KO_EXISTANT : Encours existant
--			    @CODE_KO_VIDE : Adresse de prise vide
--			    @CODE_KO_INCORRECT : Mission incorrecte
--			    @CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_INCOMPATIBLE : Incompatibilité outil/charges
--			    @CODE_KO_INATTENDU : Absence données dimensionnelles
--			    @CODE_KO_PLEIN : Adresse dépose pleine
--			    @CODE_KO_INTERDIT : Prise ou dépose interdite
--			    @CODE_KO_CHARGE : Mission existante liée à la charge
-- Descriptif		: Affinage d'une adresse
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFINEADRESSE]
	@v_cyclique bit,
	@v_iag_idagv tinyint,
	@v_ord_idordre int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_mis_idmission int,
	@v_mis_idcharge int,
	@v_chg_idcharge int,
	@v_chg_offsetprofondeur int,
	@v_chg_offsetniveau int,
	@v_chg_offsetcolonne int,
	@v_chg_couche tinyint,
	@v_chg_rang smallint,
	@v_bas_type_magasin tinyint,
	@v_bas_rayonnage bit,
	@v_bas_gerbage bit,
	@v_bas_accumulation bit,
	@v_bas_emplacement bit,
	@v_tac_idtache int,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint,
	@v_tac_offsetprofondeur int,
	@v_tac_offsetniveau int,
	@v_tac_offsetcolonne int,
	@v_position tinyint,
	@v_accesbase bit,
	@v_ata_idaction int,
	@v_act_occupation smallint,
	@v_delta smallint,
	@v_tag_idtypeagv tinyint,
	@v_tag_fourche smallint,
	@v_hauteur smallint,
	@v_longueur smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_EXISTANT tinyint,
	@CODE_KO_VIDE tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_INTERDIT tinyint,
	@CODE_KO_CHARGE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_RELANCE_INTERNE tinyint,
	@DESC_AFFINAGE_ADRESSE tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_EXISTANT = 3
	SET @CODE_KO_VIDE = 10
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_CHARGE = 19
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @ACTI_PRIMAIRE = 0
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_RELANCE_INTERNE = 11	
	SET @DESC_AFFINAGE_ADRESSE = 12
	SET @DESC_ENVOYE = 13
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN AFFINEADRESSE
	END
	-- Vérification d'un affinage d'adresse nécessaire
	DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT MIS_IDMISSION, MIS_IDCHARGE, TAC_IDTACHE, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
		TAC_ACCES_BASE, ATA_IDACTION, ATA_OPTION_ACTION, ACT_OCCUPATION, BAS_TYPE_MAGASIN, BAS_RAYONNAGE, BAS_GERBAGE, BAS_ACCUMULATION, BAS_EMPLACEMENT
		FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE, ACTION, ADRESSE, BASE, MISSION WHERE TAC_IDORDRE = @v_ord_idordre AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
		AND ACT_IDACTION = ATA_IDACTION AND ACT_CHARGE = 1 AND ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE AND ADR_SOUSBASE = TAC_IDADRSSBASE AND ADR_TYPE = 1
		AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE AND MIS_IDMISSION = TAC_IDMISSION AND ((BAS_TYPE_MAGASIN = @TYPE_INTERFACE) OR (BAS_TYPE_MAGASIN = @TYPE_STOCK AND BAS_ACCUMULATION = 0)
		OR (BAS_TYPE_MAGASIN IN (@TYPE_STOCK, @TYPE_PREPARATION) AND BAS_ACCUMULATION = 1 AND ((TAC_OFSPROFONDEUR IS NULL) OR (TAC_OFSNIVEAU IS NULL) OR (TAC_OFSCOLONNE IS NULL))))
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_mis_idcharge, @v_tac_idtache, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
		@v_accesbase, @v_ata_idaction, @v_position, @v_act_occupation, @v_bas_type_magasin, @v_bas_rayonnage, @v_bas_gerbage, @v_bas_accumulation, @v_bas_emplacement
	IF @@FETCH_STATUS = 0
	BEGIN
		WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
		BEGIN
			-- Interdiction d'encours simultanés vers l'adresse après affinage de l'adresse
			IF ((@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND @v_bas_emplacement = 1 AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDORDRE <> @v_ord_idordre AND (TAC_IDETAT IN (@ETAT_ENCOURS, @ETAT_STOPPE) OR (TAC_IDETAT = @ETAT_ENATTENTE AND TAC_DSCETAT IN (@DESC_RELANCE_MISSION, @DESC_RELANCE_INTERNE)))
				AND TAC_IDADRSYS = @v_tac_idsystemeexecution AND TAC_IDADRBASE = @v_tac_idbaseexecution AND TAC_IDADRSSBASE = @v_tac_idsousbaseexecution AND TAC_ACCES_BASE = @v_accesbase AND ((TAC_OFSPROFONDEUR IS NOT NULL) OR (TAC_OFSNIVEAU IS NOT NULL) OR (TAC_OFSCOLONNE IS NOT NULL))))
				OR (@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND @v_bas_emplacement = 0)
				OR ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0)))
			BEGIN
				IF @v_act_occupation = 1
				BEGIN
					IF EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_tac_idsystemeexecution AND ADR_BASE = @v_tac_idbaseexecution AND ADR_SOUSBASE = @v_tac_idsousbaseexecution
						AND ADR_AUT_PRISE = 1)
					BEGIN
						IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
							SELECT TOP 1 @v_chg_idcharge = CHG_ID, @v_chg_couche = CHG_COUCHE, @v_chg_rang = CHG_RANG, @v_chg_offsetprofondeur = CHG_POSY, @v_chg_offsetniveau = CHG_POSZ, @v_hauteur = HAUTEUR
								FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
								WHERE CHG_ADR_KEYSYS = @v_tac_idsystemeexecution AND CHG_ADR_KEYBASE = @v_tac_idbaseexecution
								AND CHG_ADR_KEYSSBASE = @v_tac_idsousbaseexecution AND CHG_COUCHE = ISNULL(@v_chg_couche, CHG_COUCHE) AND CHG_TODESTROY = 0
								AND NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDCHARGE = CHG_ID AND MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE))
								ORDER BY CASE ISNULL(@v_accesbase, 0) WHEN 0 THEN CHG_POSY ELSE -CHG_POSY END, CHG_COUCHE DESC, CHG_POSZ DESC
						ELSE IF ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
							SELECT TOP 1 @v_chg_idcharge = CHG_ID FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_tac_idsystemeexecution AND CHG_ADR_KEYBASE = @v_tac_idbaseexecution
								AND CHG_ADR_KEYSSBASE = @v_tac_idsousbaseexecution AND CHG_TODESTROY = 0
						IF @v_chg_idcharge IS NOT NULL
						BEGIN
							IF ((@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_tac_idsystemeexecution
								AND STR_BASE = @v_tac_idbaseexecution AND STR_SOUSBASE = @v_tac_idsousbaseexecution AND STR_COUCHE = @v_chg_couche
								AND STR_AUTORISATION_PRISE = 1 AND ((@v_bas_emplacement = 1 AND @v_chg_offsetprofondeur BETWEEN STR_LONGUEUR_DEBUT_COURANTE AND STR_LONGUEUR_FIN_COURANTE
								AND ((@v_bas_gerbage = 0) OR (@v_bas_gerbage = 1 AND @v_chg_offsetniveau + @v_hauteur <= STR_HAUTEUR_COURANTE))) OR (@v_bas_emplacement = 0))))
								OR ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0)))
							BEGIN
								IF ((@v_mis_idcharge = @v_chg_idcharge) OR (@v_mis_idcharge IS NULL))
								BEGIN
									IF ((@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND @v_bas_emplacement = 0)
										OR (@v_mis_idcharge IS NOT NULL) OR (@v_mis_idcharge IS NULL AND NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND MIS_IDCHARGE = @v_chg_idcharge)))
									BEGIN
										IF NOT (@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND @v_bas_emplacement = 0)
											AND @v_mis_idcharge IS NULL AND @v_chg_idcharge IS NOT NULL
										BEGIN
											UPDATE MISSION SET MIS_IDCHARGE = @v_chg_idcharge WHERE MIS_IDMISSION = @v_mis_idmission
											SET @v_error = @@ERROR
											IF @v_error <> 0
												SET @v_status = @CODE_KO_SQL
										END
										IF @v_status = @CODE_OK AND @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
										BEGIN
											-- Vérification de l'adéquation entre la capacité de l'outil (en prodondeur et niveau) et les charges à prendre
											IF NOT EXISTS (SELECT 1 FROM (SELECT ROW_NUMBER() OVER (ORDER BY CHG_RANG) AS PROFONDEUR, COUNT(*) NIVEAU FROM TACHE, MISSION, CHARGE WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE
												GROUP BY CHG_RANG) OCCUPATION CROSS JOIN TYPE_AGV, INFO_AGV WHERE IAG_ID = @v_iag_idagv AND TAG_ID = IAG_TYPE AND ((PROFONDEUR > TAG_PROFONDEUR) OR (NIVEAU > TAG_NIVEAU)))
												AND NOT EXISTS (SELECT 1 FROM (SELECT DISTINCT CHG_POSZ FROM (SELECT MIN(CHG_POSZ) CHG_POSZ FROM TACHE, MISSION, CHARGE WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE
												GROUP BY CHG_RANG) OCCUPATION) OCCUPATION HAVING COUNT(*) > 1)
												OR (@v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1 AND @v_bas_emplacement = 0)
											BEGIN
												IF @v_bas_emplacement = 1
												BEGIN
													SELECT @v_tag_fourche = TAG_FOURCHE FROM INFO_AGV, TYPE_AGV WHERE IAG_ID = @v_iag_idagv AND TAG_ID = IAG_TYPE AND TAG_TYPE_OUTIL IN (1, 2)
													-- Calcul de la longueur totale des charges à prendre, l'offset de profondeur, l'offset de niveau
													SELECT @v_longueur = MAX(CHG_POSY + LONGUEUR) - MIN(CHG_POSY), @v_chg_offsetprofondeur = MIN(CHG_POSY), @v_chg_offsetniveau = MIN(CHG_POSZ)
														FROM TACHE, MISSION, CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
														WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE
													SELECT TOP 1 @v_chg_offsetcolonne = CHG_POSX
														FROM TACHE, MISSION, CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
														WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE ORDER BY ABS(CHG_POSX)													
													IF @v_longueur < @v_tag_fourche AND ISNULL(@v_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
														SET @v_delta = CASE @v_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
															WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_longueur END
													ELSE
														SET @v_delta = 0
													IF ISNULL(@v_accesbase, 0) = 0
														SET @v_tac_offsetprofondeur = @v_chg_offsetprofondeur - @v_delta
													ELSE
														SET @v_tac_offsetprofondeur = @v_chg_offsetprofondeur + @v_longueur + @v_delta
													SET @v_tac_offsetniveau = @v_chg_offsetniveau
													SET @v_tac_offsetcolonne = @v_chg_offsetcolonne
												END
												ELSE
													SELECT @v_tac_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE ELSE STR_LONGUEUR_DEBUT_COURANTE END,
														@v_tac_offsetniveau = STR_COTE, @v_tac_offsetcolonne = 0
														FROM STRUCTURE WHERE STR_SYSTEME = @v_tac_idsystemeexecution AND STR_BASE = @v_tac_idbaseexecution AND STR_SOUSBASE = @v_tac_idsousbaseexecution
														AND STR_COUCHE = @v_chg_couche
												UPDATE TACHE SET TAC_OFSPROFONDEUR = @v_tac_offsetprofondeur, TAC_OFSNIVEAU = @v_tac_offsetniveau, TAC_OFSCOLONNE = @v_tac_offsetcolonne
													WHERE ((TAC_IDTACHE = @v_tac_idtache) OR (TAC_IDORDRE = @v_ord_idordre AND ((TAC_OFSPROFONDEUR IS NOT NULL) OR (TAC_OFSNIVEAU IS NOT NULL) OR (TAC_OFSCOLONNE IS NOT NULL))))
												SET @v_error = @@ERROR
												IF @v_error <> 0
													SET @v_status = @CODE_KO_SQL
												ELSE
													SET @v_status = @CODE_OK
											END
											ELSE
												SET @v_status = @CODE_KO_INCOMPATIBLE
										END
										ELSE
											SET @v_status = @CODE_OK
									END
									ELSE
										SET @v_status = @CODE_KO_CHARGE
								END
								ELSE
									SET @v_status = @CODE_KO_INCORRECT
							END
							ELSE
								SET @v_status = @CODE_KO_INATTENDU
						END
						ELSE
							SET @v_status = @CODE_KO_VIDE
					END
					ELSE
						SET @v_status = @CODE_KO_INTERDIT
				END
				ELSE IF @v_act_occupation = -1
				BEGIN
					IF EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_tac_idsystemeexecution AND ADR_BASE = @v_tac_idbaseexecution AND ADR_SOUSBASE = @v_tac_idsousbaseexecution
						AND ADR_AUT_DEPOSE = 1)
					BEGIN
						IF @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM TACHE, MISSION WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND MIS_IDCHARGE IS NULL)
							BEGIN
								SELECT @v_tag_idtypeagv = TAG_ID, @v_tag_fourche = TAG_FOURCHE FROM INFO_AGV, TYPE_AGV WHERE IAG_ID = @v_iag_idagv AND TAG_ID = IAG_TYPE AND TAG_TYPE_OUTIL IN (1, 2)
								IF EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDORDRE = @v_ord_idordre HAVING COUNT(*) > 1)
								BEGIN
									-- Calcul de la longueur et la hauteur totale des charges à déposer
									SELECT @v_hauteur = SUM(HAUTEUR), @v_longueur = MAX(CHG_POSY1) - MIN(CHG_POSY2), @v_position = MAX(CHG_POSITION) FROM (SELECT CHG_POSY + LONGUEUR CHG_POSY1, CHG_POSY CHG_POSY2,
										HAUTEUR, CHG_POSITION FROM TACHE, MISSION, CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
										WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE) DIMENSION
									-- Inhibition du gerbage dans le cas de plusieurs charges en profondeur ou en colonne
									IF EXISTS (SELECT 1 FROM TACHE, MISSION, CHARGE, ADRESSE WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_IDMISSION = TAC_IDMISSION AND CHG_ID = MIS_IDCHARGE
										AND ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE AND ((ADR_PROFONDEUR > 1) OR (ADR_COLONNE > 1)))
										SET @v_bas_gerbage = 0
								END
								ELSE
								BEGIN
									-- Récupérer les dimensions de la charge du gabarit ou de l'emballage
									SELECT @v_hauteur = HAUTEUR, @v_longueur = LONGUEUR, @v_position = CHG_POSITION FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE,
										CHG_GABARIT, CHG_EMBALLAGE) WHERE CHG_ID = @v_mis_idcharge AND CHG_TODESTROY = 0
								END
								SELECT @v_status = RETOUR, @v_chg_offsetprofondeur = OFFSETPROFONDEUR, @v_chg_offsetniveau = OFFSETNIVEAU, @v_chg_offsetcolonne = OFFSETCOLONNE
									FROM dbo.SPV_OFFSETADRESSE(@v_tag_idtypeagv, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, NULL, @v_accesbase, @v_bas_type_magasin,
									@v_bas_rayonnage, @v_bas_gerbage, @v_bas_emplacement, @v_mis_idcharge, @v_hauteur, @v_longueur, @v_position, 0)
								SET @v_error = @@ERROR
								IF @v_status = @CODE_OK AND @v_error = 0
								BEGIN
									IF @v_bas_emplacement = 1
									BEGIN
										IF @v_longueur < @v_tag_fourche AND ISNULL(@v_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
											SET @v_delta = CASE @v_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_longueur) / 2
												WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_longueur END
										ELSE
											SET @v_delta = 0
										IF ISNULL(@v_accesbase, 0) = 0
											SET @v_tac_offsetprofondeur = @v_chg_offsetprofondeur - @v_delta
										ELSE
											SET @v_tac_offsetprofondeur = @v_chg_offsetprofondeur + @v_longueur + @v_delta
									END
									ELSE
										SET @v_tac_offsetprofondeur = @v_chg_offsetprofondeur
									SET @v_tac_offsetniveau = @v_chg_offsetniveau
									SET @v_tac_offsetcolonne = @v_chg_offsetcolonne
									UPDATE TACHE SET TAC_OFSPROFONDEUR = @v_tac_offsetprofondeur, TAC_OFSNIVEAU = @v_tac_offsetniveau, TAC_OFSCOLONNE = @v_tac_offsetcolonne
										WHERE TAC_IDORDRE = @v_ord_idordre
									SET @v_error = @@ERROR
									IF @v_error <> 0
										SET @v_status = @CODE_KO_SQL
									ELSE
										SET @v_status = @CODE_OK
								END
							END
							ELSE
								SET @v_status = @CODE_KO_INCORRECT
						END
						ELSE
						BEGIN
							IF @v_mis_idcharge IS NOT NULL
								SET @v_status = @CODE_OK
							ELSE
								SET @v_status = @CODE_KO_INCORRECT
						END
					END
					ELSE
						SET @v_status = @CODE_KO_INTERDIT
					IF @v_status = @CODE_OK AND @v_cyclique = 1
					BEGIN
						DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDMISSION FROM TACHE WHERE TAC_IDORDRE = @v_ord_idordre
						OPEN c_mission
						FETCH NEXT FROM c_mission INTO @v_mis_idmission
						WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
						BEGIN
							EXEC @v_status = SPV_RELANCEORDRE @v_iag_idagv, @v_ord_idordre, @v_mis_idmission, @DESC_RELANCE_MISSION
							SET @v_error = @@ERROR
							IF @v_status IN (@CODE_KO, @CODE_OK) AND @v_error = 0
								SET @v_status = @CODE_OK
							FETCH NEXT FROM c_mission INTO @v_mis_idmission
						END
						CLOSE c_mission
						DEALLOCATE c_mission
						IF @v_status IN (@CODE_KO, @CODE_OK) AND @v_error = 0
							SET @v_status = @CODE_OK
					END
				END
			END
			ELSE
				SET @v_status = @CODE_KO_EXISTANT
			FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_mis_idcharge, @v_tac_idtache, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
				@v_accesbase, @v_ata_idaction, @v_position, @v_act_occupation, @v_bas_type_magasin, @v_bas_rayonnage, @v_bas_gerbage, @v_bas_accumulation, @v_bas_emplacement
		END
	END
	ELSE
		SET @v_retour = @CODE_OK
	CLOSE c_tache
	DEALLOCATE c_tache
	IF @v_retour = @CODE_KO AND @v_status = @CODE_OK
	BEGIN
		IF @v_act_occupation = 1
		BEGIN
			-- Vérification de l'absence de conflit entre une charge et l'extrémité des fourches
			IF EXISTS (SELECT 1 FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE),
				STRUCTURE WHERE CHG_ADR_KEYSYS = @v_tac_idsystemeexecution AND CHG_ADR_KEYBASE = @v_tac_idbaseexecution AND CHG_ADR_KEYSSBASE = @v_tac_idsousbaseexecution AND CHG_COUCHE = @v_chg_couche
				AND CHG_TODESTROY = 0 AND NOT EXISTS (SELECT 1 FROM TACHE, MISSION WHERE MIS_IDMISSION = TAC_IDMISSION AND MIS_IDCHARGE = CHG_ID AND MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE))
				AND STR_SYSTEME = CHG_ADR_KEYSYS AND STR_BASE = CHG_ADR_KEYBASE AND STR_SOUSBASE = CHG_ADR_KEYSSBASE AND STR_COUCHE = CHG_COUCHE
				AND (((ISNULL(@v_accesbase, 0) = 0) AND CHG_RANG < @v_chg_rang AND (CHG_POSY < (@v_tac_offsetprofondeur + @v_tag_fourche + ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL))))
				OR ((@v_accesbase = 1) AND CHG_RANG > @v_chg_rang AND ((CHG_POSY + LONGUEUR) > (@v_tac_offsetprofondeur - @v_tag_fourche - ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL))))))
				SET @v_status = @CODE_KO_INCORRECT
		END
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	END
	ELSE IF @v_retour = @CODE_KO
		SET @v_retour = @v_status
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN AFFINEADRESSE
		ELSE
			COMMIT TRAN AFFINEADRESSE
	END
	IF @v_local = 1 AND @v_retour <> @CODE_OK
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv AND ((ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE) OR ORD_IDETAT = @ETAT_ENCOURS))
		BEGIN
			BEGIN TRAN
			-- L'affinage a échoué, interruption des ordres de l'AGV
			SET @v_error = 0
			SET @v_status = @CODE_KO
			SET @v_ord_idordre = NULL
			SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV
				WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND (ORD_DSCETAT IS NULL OR ORD_DSCETAT <> @DESC_ENVOYE)
				ORDER BY ORD_POSITION
			EXEC @v_status = SPV_INTERROMPTORDRE @v_ord_idordre, @DESC_AFFINAGE_ADRESSE
			SET @v_error = @@ERROR
			IF NOT (@v_status = @CODE_OK AND @v_error = 0)
				ROLLBACK TRAN
			ELSE
				COMMIT TRAN
		END
	END
	RETURN @v_retour

