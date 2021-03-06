SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_OFFSETADRESSE
-- Paramètre d'entrée	: @v_tag_idtypeagv : Identifiant type AGV
--			  @v_adr_idsysteme : Clé système
--			  @v_adr_idbase : Clé base
--			  @v_adr_idsousbase : Clé sous-base
--			  @v_adr_niveau : Niveau
--			  @v_accesbase : Côté accès base
--			  @v_bas_type_magasin : Type magasin
--			  @v_bas_rayonnage : Rayonnage
--			  @v_bas_gerbage : Gerbage
--			  @v_bas_emplacement : Emplacement
--			  @v_chg_idcharge : Identifiant charge
--			  @v_hauteur : Hauteur
--			  @v_longueur : Longueur
--			  @v_chg_position : Position
--			    0 : Tablier
--			    1 : Centrée
--			    2 : Bout de fourche
--			  @v_forcage : Forçage
-- Paramètre de sortie	: RETOUR :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCOMPATIBLE : Absence longueur fourche
--			    @CODE_KO_INATTENDU : Absence données dimensionnelles
--			    @CODE_KO_PLEIN : Adresse pleine
--			    @CODE_KO_SPECIFIQUE : Echec évaluation conditions gerbage
--			    @CODE_KO_ACTION_INCONNUE : Action inconnue
--			  OFFSETPROFONDEUR : Offset profondeur
--			  OFFSETNIVEAU : Offset niveau
--			  OFFSETCOLONNE : Offset colonne
-- Descriptif		: Calcul des offsets sur une adresse
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_OFFSETADRESSE](@v_tag_idtypeagv tinyint, @v_adr_idsysteme bigint, @v_adr_idbase bigint,
	@v_adr_idsousbase bigint, @v_adr_niveau tinyint, @v_accesbase bit, @v_bas_type_magasin tinyint, @v_bas_rayonnage bit, @v_bas_gerbage bit,
	@v_bas_emplacement bit, @v_chg_idcharge_next int, @v_hauteur smallint, @v_longueur smallint, @v_chg_position tinyint, @v_forcage bit)
	RETURNS @offsetadresse TABLE (RETOUR int NOT NULL, OFFSETPROFONDEUR int NULL, OFFSETNIVEAU int NULL, OFFSETCOLONNE int NULL)
AS
BEGIN

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_par_valeur varchar(128),
	@v_tag_fourche smallint,
	@v_str_couche tinyint,
	@v_str_hauteur smallint,
	@v_str_longueur_debut smallint,
	@v_str_longueur_fin smallint,
	@v_str_cote smallint,
	@v_str_ecart smallint,
	@v_profondeur smallint,
	@v_rang smallint,
	@v_chg_idcharge_last int,
	@v_gerbage bit,
	@v_offsetprofondeur int,
	@v_offsetniveau int,
	@v_offsetcolonne int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_INATTENDU tinyint,
	@CODE_KO_PLEIN tinyint,
	@CODE_KO_SPECIFIQUE tinyint,
	@CODE_KO_ACTION_INCONNUE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_PRISE smallint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_INATTENDU = 16
	SET @CODE_KO_PLEIN = 17
	SET @CODE_KO_SPECIFIQUE = 20
	SET @CODE_KO_ACTION_INCONNUE = 29
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2
	SET @ACTI_PRISE = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	-- Vérification des informations AGV
	IF @v_tag_idtypeagv IS NULL
		SELECT TOP 1 @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_TYPE_OUTIL IN (1, 2) ORDER BY TAG_FOURCHE DESC
	ELSE
		SELECT @v_tag_fourche = TAG_FOURCHE FROM TYPE_AGV WHERE TAG_ID = @v_tag_idtypeagv AND TAG_TYPE_OUTIL IN (1, 2)
	IF @v_tag_fourche IS NOT NULL
	BEGIN
		-- Contrôle de la position
		IF EXISTS (SELECT 1 FROM OPTION_ACTION WHERE OPA_ACTION = @ACTI_PRISE AND OPA_ID = ISNULL(@v_chg_position, @OPTI_TABLIER))
		BEGIN
			IF ((@v_bas_gerbage = 1 AND @v_hauteur IS NOT NULL) OR @v_bas_gerbage = 0) AND @v_longueur IS NOT NULL
			BEGIN
				-- Détermination de la couche et de l'emplacement approprié de stockage ou de préparation
				IF EXISTS (SELECT 1 FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme
					AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
					AND STR_LONGUEUR_FIN_COURANTE IS NOT NULL AND ((@v_bas_gerbage = 1 AND STR_HAUTEUR_COURANTE IS NOT NULL) OR (@v_bas_gerbage = 0))
					AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1)))
				BEGIN
					IF @v_bas_emplacement = 1 AND EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
						AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0)
					BEGIN
						SET @v_profondeur = CASE WHEN @v_longueur >= @v_tag_fourche THEN @v_longueur ELSE
							CASE ISNULL(@v_chg_position, @OPTI_TABLIER) WHEN @OPTI_CENTREE THEN @v_longueur + (@v_tag_fourche - @v_longueur) / 2
							WHEN @OPTI_FOURCHE THEN @v_longueur ELSE @v_tag_fourche END END
						IF ((@v_bas_type_magasin = @TYPE_PREPARATION) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 0))
						BEGIN
							-- Préparation ou stock sans rayonnage, sans gerbage
							SET @v_str_couche = 1
							SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE, @v_str_ecart = ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL),
								@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
								@v_offsetcolonne = 0
								FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
								AND STR_COUCHE = @v_str_couche AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
							IF ISNULL(@v_accesbase, 0) = 0
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY - @v_str_ecart - @v_profondeur FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY
							ELSE
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur - @v_longueur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY DESC
							IF (@v_offsetprofondeur + @v_longueur) > @v_str_longueur_fin
							BEGIN
								IF ISNULL(@v_accesbase, 0) = 0
									SET @v_offsetprofondeur = @v_str_longueur_fin - @v_longueur
								ELSE
									SET @v_status = @CODE_KO_PLEIN
							END
						END
						ELSE IF @v_bas_type_magasin = @TYPE_STOCK AND @v_bas_rayonnage = 0 AND @v_bas_gerbage = 1
						BEGIN
							-- Stock sans rayonnage avec gerbage
							SET @v_str_couche = 1
							SET @v_gerbage = 0
							SELECT @v_str_cote = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE, @v_str_ecart = ISNULL(STR_ECART_EXPLOITATION, STR_ECART_INDUSTRIEL),
								@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE - @v_longueur ELSE STR_LONGUEUR_DEBUT_COURANTE END,
								@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE
								FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
								AND STR_COUCHE = @v_str_couche AND ((STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
							IF ISNULL(@v_accesbase, 0) = 0
								SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_offsetprofondeur = CHG_POSY, @v_rang = CHG_RANG FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY, CHG_POSZ DESC
							ELSE
								SELECT TOP 1 @v_chg_idcharge_last = CHG_ID, @v_offsetprofondeur = CHG_POSY + LONGUEUR, @v_rang = CHG_RANG FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche ORDER BY CHG_POSY + LONGUEUR DESC , CHG_POSZ DESC
							SELECT @v_offsetniveau = SUM(ISNULL(CHG_HAUTEUR, ISNULL(GBR_HAUTEUR, EMB_HAUTEUR)))
								FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
								LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
								AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang
							SELECT TOP 1 @v_offsetcolonne = CHG_POSX
								FROM CHARGE LEFT OUTER JOIN GABARIT ON GBR_ID = CHG_GABARIT
								LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
								AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = @v_rang ORDER BY ABS(CHG_POSX)
							IF ((@v_offsetniveau + @v_hauteur) <= @v_str_hauteur
								AND NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDCHARGE = @v_chg_idcharge_last))
							BEGIN
								-- Récupération de la fonction d'évalution des conditions de gerbage
								SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'EVALUE_GERBAGE'
								IF (@v_par_valeur IS NOT NULL)
								BEGIN
									EXEC @v_gerbage = @v_par_valeur @v_chg_idcharge_last, @v_chg_idcharge_next
									SET @v_error = @@ERROR
								END
								ELSE
									SET @v_gerbage = 1
							END
							IF @v_status = @CODE_OK AND @v_error = 0
							BEGIN
								IF @v_gerbage = 0
								BEGIN
									SET @v_offsetniveau = @v_str_cote
									SET @v_offsetcolonne = 0
								END
								IF ISNULL(@v_accesbase, 0) = 0
									SELECT TOP 1 @v_offsetprofondeur = CASE WHEN CHG_POSY - @v_str_ecart - @v_profondeur > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY - @v_str_ecart - @v_profondeur END
										FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
										AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang - 1 END ORDER BY CHG_POSY
								ELSE
								BEGIN
									IF EXISTS (SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
										AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang + 1 END)
										SELECT TOP 1 @v_offsetprofondeur = CASE WHEN CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY + LONGUEUR + @v_str_ecart + @v_profondeur END - @v_longueur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
											WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
											AND CHG_TODESTROY = 0 AND CHG_COUCHE = @v_str_couche AND CHG_RANG = CASE @v_gerbage WHEN 0 THEN @v_rang ELSE @v_rang + 1 END ORDER BY CHG_POSY + LONGUEUR DESC
									ELSE
										SET @v_offsetprofondeur = @v_offsetprofondeur - @v_longueur
								END
								IF (@v_offsetprofondeur + @v_longueur) > @v_str_longueur_fin
								BEGIN
									IF ISNULL(@v_accesbase, 0) = 0
										SET @v_offsetprofondeur = @v_str_longueur_fin - @v_longueur
									ELSE
										SET @v_status = @CODE_KO_PLEIN
								END				
								IF @v_offsetprofondeur < @v_str_longueur_debut
								BEGIN
									IF ISNULL(@v_accesbase, 0) = 1
										SET @v_offsetprofondeur = @v_str_longueur_debut
								END				
							END
							ELSE
								SET @v_status = @CODE_KO_SPECIFIQUE
						END
						ELSE
						BEGIN
							-- Stock avec rayonnage
							IF ISNULL(@v_accesbase, 0) = 0
							BEGIN
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase
									AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase AND CHG_TODESTROY = 0 ORDER BY CHG_POSY
								SELECT TOP 1 @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
									@v_offsetprofondeur = CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END,
									@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
									@v_offsetcolonne = 0
									FROM (SELECT B.STR_COTE, B.STR_LONGUEUR_DEBUT_INITIALE, B.STR_LONGUEUR_FIN_INITIALE, B.STR_HAUTEUR_COURANTE, ISNULL((SELECT TOP 1 CHG_POSY - ISNULL(B.STR_ECART_EXPLOITATION, B.STR_ECART_INDUSTRIEL) - @v_profondeur FROM CHARGE
									WHERE CHG_ADR_KEYSYS = STR_SYSTEME AND CHG_ADR_KEYBASE = STR_BASE AND CHG_ADR_KEYSSBASE = STR_SOUSBASE AND CHG_TODESTROY = 0 AND CHG_COUCHE = STR_COUCHE ORDER BY CHG_POSY), B.STR_LONGUEUR_FIN_COURANTE - @v_longueur) CHG_POSY,
									B.STR_LONGUEUR_DEBUT_COURANTE, B.STR_LONGUEUR_FIN_COURANTE FROM STRUCTURE B WHERE B.STR_SYSTEME = @v_adr_idsysteme AND B.STR_BASE = @v_adr_idbase AND B.STR_SOUSBASE = @v_adr_idsousbase
									AND ((@v_adr_niveau IS NULL) OR (@v_adr_niveau IS NOT NULL AND B.STR_COUCHE = @v_adr_niveau)) AND ((B.STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
									AND NOT EXISTS (SELECT 1 FROM STRUCTURE C WHERE C.STR_SYSTEME = B.STR_SYSTEME AND C.STR_BASE = B.STR_BASE AND C.STR_SOUSBASE = B.STR_SOUSBASE
									AND C.STR_COUCHE < B.STR_COUCHE AND C.STR_AUTORISATION_DEPOSE = 0)) A
									WHERE CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END + @v_longueur <= STR_LONGUEUR_FIN_COURANTE AND CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END >= STR_LONGUEUR_DEBUT_COURANTE
									ORDER BY CASE WHEN CHG_POSY > @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END DESC, STR_COTE
							END
							ELSE
							BEGIN
								SELECT TOP 1 @v_offsetprofondeur = CHG_POSY + LONGUEUR FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = @v_adr_idsysteme AND CHG_ADR_KEYBASE = @v_adr_idbase AND CHG_ADR_KEYSSBASE = @v_adr_idsousbase
									AND CHG_TODESTROY = 0 ORDER BY CHG_POSY + LONGUEUR DESC
								SELECT TOP 1 @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
									@v_offsetprofondeur = CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END - @v_longueur,
									@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
									@v_offsetcolonne = 0
									FROM (SELECT B.STR_COTE, B.STR_LONGUEUR_DEBUT_INITIALE, B.STR_LONGUEUR_FIN_INITIALE, B.STR_HAUTEUR_COURANTE, ISNULL((SELECT TOP 1 CHG_POSY + LONGUEUR + ISNULL(B.STR_ECART_EXPLOITATION, B.STR_ECART_INDUSTRIEL) + @v_profondeur FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
									WHERE CHG_ADR_KEYSYS = STR_SYSTEME AND CHG_ADR_KEYBASE = STR_BASE AND CHG_ADR_KEYSSBASE = STR_SOUSBASE AND CHG_TODESTROY = 0 AND CHG_COUCHE = STR_COUCHE ORDER BY CHG_POSY DESC), B.STR_LONGUEUR_DEBUT_COURANTE + @v_longueur) CHG_POSY, B.STR_LONGUEUR_DEBUT_COURANTE,
									B.STR_LONGUEUR_FIN_COURANTE FROM STRUCTURE B WHERE B.STR_SYSTEME = @v_adr_idsysteme AND B.STR_BASE = @v_adr_idbase AND B.STR_SOUSBASE = @v_adr_idsousbase
									AND ((@v_adr_niveau IS NULL) OR (@v_adr_niveau IS NOT NULL AND B.STR_COUCHE = @v_adr_niveau)) AND ((B.STR_AUTORISATION_DEPOSE = 1) OR (@v_forcage = 1))
									AND NOT EXISTS (SELECT 1 FROM STRUCTURE C WHERE C.STR_SYSTEME = B.STR_SYSTEME AND C.STR_BASE = B.STR_BASE AND C.STR_SOUSBASE = B.STR_SOUSBASE
									AND C.STR_COUCHE < B.STR_COUCHE AND C.STR_AUTORISATION_DEPOSE = 0)) A
									WHERE CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END <= STR_LONGUEUR_FIN_COURANTE AND CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END + @v_longueur >= STR_LONGUEUR_DEBUT_COURANTE
									ORDER BY CASE WHEN CHG_POSY < @v_offsetprofondeur THEN @v_offsetprofondeur ELSE CHG_POSY END, STR_COTE									
							END
						END
					END
					ELSE IF @v_bas_emplacement = 1
					BEGIN
						SET @v_str_couche = 1
						SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
							@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE - @v_longueur ELSE STR_LONGUEUR_DEBUT_COURANTE END,
							@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
							@v_offsetcolonne = 0
							FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
							AND ((@v_adr_niveau IS NULL AND STR_COUCHE = @v_str_couche) OR (@v_adr_niveau IS NOT NULL AND STR_COUCHE = @v_adr_niveau))
					END
					ELSE IF @v_bas_emplacement = 0
					BEGIN
						SET @v_str_couche = 1
						SELECT @v_offsetniveau = STR_COTE, @v_str_hauteur = STR_HAUTEUR_COURANTE,
							@v_offsetprofondeur = CASE WHEN ISNULL(@v_accesbase, 0) = 0 THEN STR_LONGUEUR_FIN_COURANTE ELSE STR_LONGUEUR_DEBUT_COURANTE END,
							@v_str_longueur_debut = STR_LONGUEUR_DEBUT_COURANTE, @v_str_longueur_fin = STR_LONGUEUR_FIN_COURANTE,
							@v_offsetcolonne = 0
							FROM STRUCTURE WHERE STR_SYSTEME = @v_adr_idsysteme AND STR_BASE = @v_adr_idbase AND STR_SOUSBASE = @v_adr_idsousbase
							AND ((@v_adr_niveau IS NULL AND STR_COUCHE = @v_str_couche) OR (@v_adr_niveau IS NOT NULL AND STR_COUCHE = @v_adr_niveau))
					END
					IF @v_status = @CODE_OK
					BEGIN
						IF @v_offsetprofondeur >= @v_str_longueur_debut AND ((@v_offsetniveau >= 0 AND @v_str_hauteur IS NULL)
							OR ((@v_offsetniveau + @v_hauteur) <= @v_str_hauteur AND @v_str_hauteur IS NOT NULL))
							SET @v_status = @CODE_OK
						ELSE
							SET @v_status = @CODE_KO_PLEIN
					END
				END
				ELSE
					SET @v_status = @CODE_KO_INATTENDU
			END
			ELSE
				SET @v_status = @CODE_KO_INATTENDU
		END
		ELSE
			SET @v_status = @CODE_KO_ACTION_INCONNUE
	END
	ELSE
		SET @v_status = @CODE_KO_INCOMPATIBLE
	SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END

	INSERT INTO @offsetadresse SELECT @v_retour, @v_offsetprofondeur, @v_offsetniveau, @v_offsetcolonne
	RETURN
END

